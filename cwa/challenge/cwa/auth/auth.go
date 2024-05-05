package auth

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/ryanuber/go-glob"
)

// Info about a user
type UserInfo struct {
	Username string   `json:"username"`
	Groups   []string `json:"groups"`
}

// Service for authn
type AuthenticationService struct {
	signingKey    []byte
	validity      time.Duration
	signingMethod jwt.SigningMethod
	parser        *jwt.Parser
	users         map[string]string
	groups        map[string][]string
	hasher        *PasswordHasher
}

const (
	jwtAlg     = "HS256"
	authHeader = "X-CWA-Auth"
	authCookie = "cwaid"
	validity   = 1 * time.Hour
)

// Only decodes credentials if present, makes no decisions on allowing requests.
type AuthenticationMiddleware struct {
	authsvc *AuthenticationService
	next    http.Handler
}

var (
	ErrInvalidUsernamePassword = errors.New("Invalid username/password")
)

// Context key types
type authkey string

var (
	userInfoKey = authkey("userinfo")
	svcKey      = authkey("authsvc")
)

func NewAuthenticationService(key []byte, users map[string]string, groups map[string][]string) *AuthenticationService {
	if len(key) != 256/8 {
		panic("Attempted to create AuthenticationService with wrong key length!")
	}
	svc := &AuthenticationService{
		signingKey:    deriveJWTKey(key),
		signingMethod: jwt.GetSigningMethod(jwtAlg),
		validity:      validity,
		parser: jwt.NewParser(
			jwt.WithAudience("cwa"),
			jwt.WithLeeway(2*time.Minute),
			jwt.WithValidMethods([]string{jwtAlg})),
		users:  users,
		groups: groups,
		hasher: NewPasswordHasher(),
	}
	return svc
}

func deriveJWTKey(root []byte) []byte {
	mac := hmac.New(sha256.New, []byte("jwtauthkey"))
	mac.Write(root)
	return mac.Sum(nil)
}

func (a *AuthenticationService) AuthenticateUser(username, password string) (*UserInfo, error) {
	pwhash, ok := a.users[username]
	if !ok {
		log.Printf("user %s not found", username)
		return nil, ErrInvalidUsernamePassword
	}
	if !a.hasher.VerifyHash(password, pwhash) {
		log.Printf("password hash for %s not verified", username)
		return nil, ErrInvalidUsernamePassword
	}
	ui := &UserInfo{
		Username: username,
	}
	for grp, users := range a.groups {
		for _, u := range users {
			if u == username {
				ui.Groups = append(ui.Groups, grp)
				break
			}
		}
	}
	return ui, nil
}

func (a *AuthenticationService) HashPassword(password string) string {
	return a.hasher.GenerateHash(password)
}

func (a *AuthenticationService) SignUser(ui *UserInfo) string {
	if ui == nil {
		log.Printf("Request to sign nil user")
		return ""
	}
	assertion := ui.assertionString()
	now := time.Now()
	claims := &jwt.RegisteredClaims{
		Subject:   assertion,
		NotBefore: jwt.NewNumericDate(now),
		Issuer:    "cwa",
		Audience:  jwt.ClaimStrings{"cwa"},
	}
	if a.validity.Nanoseconds() > 0 {
		exp := now.Add(a.validity)
		claims.ExpiresAt = jwt.NewNumericDate(exp)
	}
	tok := jwt.NewWithClaims(a.signingMethod, claims)
	if ss, err := tok.SignedString(a.signingKey); err != nil {
		log.Printf("Failed to generated signed token: %s", err)
		return ""
	} else {
		return ss
	}
}

func (a *AuthenticationService) ValidateToken(tokenString string) (*UserInfo, error) {
	token, err := a.parser.Parse(tokenString, a.keyFunc)
	if err != nil {
		return nil, fmt.Errorf("failed parsing token: %w", err)
	}
	if sub, err := token.Claims.GetSubject(); err != nil {
		return nil, fmt.Errorf("failed to get subject: %w", err)
	} else {
		return DecodeAssertionString(sub)
	}
}

func (a *AuthenticationService) keyFunc(t *jwt.Token) (interface{}, error) {
	return a.signingKey, nil
}

func baseCookie() *http.Cookie {
	return &http.Cookie{
		Name: authCookie,
		Path: "/",
	}
}

func LoginUser(w http.ResponseWriter, r *http.Request, ui *UserInfo) error {
	svc, ok := r.Context().Value(svcKey).(*AuthenticationService)
	if !ok {
		log.Printf("Request lacks AuthenticationService, can't login user %s", ui)
		return fmt.Errorf("No AuthenticationService in context!")
	}
	signed := svc.SignUser(ui)
	if signed == "" {
		return fmt.Errorf("No signed user data")
	}
	cookie := baseCookie()
	cookie.Value = signed
	http.SetCookie(w, cookie)
	return nil
}

func LogoutUser(w http.ResponseWriter, _ *http.Request) {
	cookie := baseCookie()
	cookie.Expires = time.Unix(0, 0)
	cookie.MaxAge = -1
	http.SetCookie(w, cookie)
}

func NewAuthenticationMiddleware(next http.Handler, authsvc *AuthenticationService) *AuthenticationMiddleware {
	return &AuthenticationMiddleware{
		authsvc: authsvc,
		next:    next,
	}
}

func (a *AuthenticationMiddleware) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ctx = context.WithValue(ctx, svcKey, a.authsvc)
	// do auth stuff
	if token := a.extractToken(r); token != "" {
		ui, err := a.authsvc.ValidateToken(token)
		if err != nil {
			if errors.Is(err, jwt.ErrTokenExpired) {
				log.Printf("expired auth token, treating as logged out: %s", err)
				LogoutUser(w, r)
			} else {
				log.Printf("error checking authentication token: %s", err)
				http.Error(w, "403 Forbidden", http.StatusForbidden)
				return
			}
		} else {
			ctx = context.WithValue(ctx, userInfoKey, ui)
		}
	}
	// pass on
	r = r.WithContext(ctx)
	a.next.ServeHTTP(w, r)
}

func (a *AuthenticationMiddleware) extractToken(r *http.Request) string {
	if h := r.Header.Get(authHeader); h != "" {
		return h
	}
	if c, err := r.Cookie(authCookie); err != nil {
		return ""
	} else {
		return c.Value
	}
}

func GetUserInfo(r *http.Request) *UserInfo {
	ctx := r.Context()
	if ui, ok := ctx.Value(userInfoKey).(*UserInfo); ok {
		return ui
	} else {
		return nil
	}
}

func DecodeAssertionString(a string) (*UserInfo, error) {
	jb, err := base64.RawURLEncoding.DecodeString(a)
	if err != nil {
		return nil, fmt.Errorf("unable to base64 decode assertion: %w", err)
	}
	buf := bytes.NewBuffer(jb)
	dec := json.NewDecoder(buf)
	var u UserInfo
	if err := dec.Decode(&u); err != nil {
		return nil, fmt.Errorf("unable to decode json data: %w", err)
	}
	return &u, nil
}

func (ui *UserInfo) assertionString() string {
	buf := &bytes.Buffer{}
	jsenc := json.NewEncoder(buf)
	if err := jsenc.Encode(ui); err != nil {
		log.Printf("Error encoding user token: %s", err)
		return ""
	}
	return base64.RawURLEncoding.EncodeToString(buf.Bytes())
}

func (ui *UserInfo) String() string {
	return fmt.Sprintf("<User %s>", ui.Username)
}

func (ui *UserInfo) InGroup(grp string) bool {
	for _, g := range ui.Groups {
		if g == grp {
			return true
		}
	}
	return false
}

func (ui *UserInfo) InGroupGlob(pat string) bool {
	for _, g := range ui.Groups {
		if glob.Glob(pat, g) {
			return true
		}
	}
	return false
}

var (
	_ http.Handler = &AuthenticationMiddleware{}
)

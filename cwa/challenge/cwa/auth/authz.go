package auth

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/ryanuber/go-glob"

	"github.com/BSidesSF/ctf-2024/cwa/config"
)

type AuthzMiddleware struct {
	requireLoggedIn bool
	requireUser     []string
	requireGroup    []string
	failCode        int
	redirect        string
	next            http.Handler
}

type AuthzPathMiddleware struct {
	prefix   string
	paths    map[string]*AuthzMiddleware
	dfltCode int
	next     http.Handler
}

type AuthzOption func(*AuthzMiddleware)
type AuthzPathOption func(*AuthzPathMiddleware)

func (a *AuthzMiddleware) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if a.CheckAndRedirect(w, r) {
		a.next.ServeHTTP(w, r)
	}
}

func (a *AuthzMiddleware) CheckAndRedirect(w http.ResponseWriter, r *http.Request) bool {
	// apply tests
	log.Printf("Performing authz checks for %s", r.URL.Path)
	user := GetUserInfo(r)
	if a.requireLoggedIn && user == nil {
		a.fail(w, r, user)
		return false
	}
	if len(a.requireUser) > 0 {
		userFound := false
		for _, v := range a.requireUser {
			if glob.Glob(v, user.Username) {
				userFound = true
				break
			}
		}
		if !userFound {
			log.Printf("required user not found for %s", user.Username)
			a.fail(w, r, user)
			return false
		}
	}
	if len(a.requireGroup) > 0 {
		groupFound := false
		for _, g := range a.requireGroup {
			if user.InGroupGlob(g) {
				groupFound = true
				break
			}
		}
		if !groupFound {
			log.Printf("required group not found for %s", user.Username)
			a.fail(w, r, user)
			return false
		}
	}
	return true
}

func (a *AuthzMiddleware) fail(w http.ResponseWriter, r *http.Request, u *UserInfo) {
	log.Printf("Authz failing for %s with code %d", u, a.failCode)
	authzErrorPage(w, r)
}

func RequireAuthz(next http.Handler, opts ...AuthzOption) *AuthzMiddleware {
	m := &AuthzMiddleware{
		next:     next,
		failCode: http.StatusUnauthorized,
	}
	for _, o := range opts {
		o(m)
	}
	return m
}

func OptRedirect(dest string) func(*AuthzMiddleware) {
	return func(m *AuthzMiddleware) {
		m.failCode = http.StatusTemporaryRedirect
		m.redirect = dest
	}
}

func OptStatusCode(code int) func(*AuthzMiddleware) {
	return func(m *AuthzMiddleware) {
		m.failCode = code
	}
}

func OptRequireLoggedIn(m *AuthzMiddleware) {
	m.requireLoggedIn = true
}

func OptRequireUser(name string) func(*AuthzMiddleware) {
	return func(m *AuthzMiddleware) {
		m.requireLoggedIn = true
		m.requireUser = []string{name}
	}
}

func OptRequireGroup(name string) func(*AuthzMiddleware) {
	return func(m *AuthzMiddleware) {
		m.requireLoggedIn = true
		m.requireGroup = []string{name}
	}
}

func OptRequireAnyUser(names []string) func(*AuthzMiddleware) {
	return func(m *AuthzMiddleware) {
		m.requireLoggedIn = true
		m.requireUser = names
	}
}

func OptRequireAnyGroup(names []string) func(*AuthzMiddleware) {
	return func(m *AuthzMiddleware) {
		m.requireLoggedIn = true
		m.requireGroup = names
	}
}

func (a *AuthzPathMiddleware) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	user := GetUserInfo(r)
	username := "(anonymous)"
	if user != nil {
		username = user.Username
	}
	p := strings.TrimPrefix(r.URL.Path, a.prefix)
	if p != r.URL.Path {
		log.Printf("Path middleware for path %s (originally %s)", p, r.URL.Path)
	} else if a.prefix != "" {
		log.Printf("Path middleware for path %s (failed prefix match)", p)
	} else {
		log.Printf("Path middleware for path %s", p)
	}
	if check, ok := a.paths[p]; ok {
		if check.CheckAndRedirect(w, r) {
			log.Printf("%s granted access to path %s", username, p)
			a.next.ServeHTTP(w, r)
			return
		} else {
			log.Printf("%s denied access to path %s", username, p)
			authzErrorPage(w, r)
			return
		}
	} else {
		// not in path database!
		if a.dfltCode == http.StatusOK {
			a.next.ServeHTTP(w, r)
			return
		} else {
			log.Printf("path %s not found in authorization config", p)
			authzErrorPage(w, r)
			return
		}
	}
}

func RequirePathAuthz(next http.Handler, pathConfigs map[string][]AuthzOption, opts ...AuthzPathOption) *AuthzPathMiddleware {
	pathMiddleware := make(map[string]*AuthzMiddleware)
	for pth, opts := range pathConfigs {
		pathMiddleware[pth] = RequireAuthz(nil, opts...)
	}
	res := &AuthzPathMiddleware{
		dfltCode: http.StatusForbidden,
		next:     next,
		paths:    pathMiddleware,
	}
	for _, opt := range opts {
		opt(res)
	}
	return res
}

func BuildPathAuthz(next http.Handler, cfg *config.Config, opts ...AuthzPathOption) *AuthzPathMiddleware {
	pths := make(map[string][]AuthzOption)
	for p, val := range cfg.Protected {
		var o []AuthzOption
		if len(val.RequiredUsers) > 0 {
			o = append(o, OptRequireAnyUser(val.RequiredUsers))
		}
		if len(val.RequiredGroups) > 0 {
			o = append(o, OptRequireAnyGroup(val.RequiredGroups))
		}
		if val.RequiredUser != "" {
			o = append(o, OptRequireUser(val.RequiredUser))
		}
		if val.RequiredGroup != "" {
			o = append(o, OptRequireGroup(val.RequiredGroup))
		}
		pths[p] = o
	}
	if cfg.FailOpen {
		opts = append(opts, WithFailOpen(true))
	}
	return RequirePathAuthz(next, pths, opts...)
}

func WithPathPrefix(prefix string) func(*AuthzPathMiddleware) {
	return func(a *AuthzPathMiddleware) {
		a.prefix = prefix
	}
}

func WithFailOpen(o bool) func(*AuthzPathMiddleware) {
	return func(a *AuthzPathMiddleware) {
		if o {
			a.dfltCode = http.StatusOK
		} else {
			a.dfltCode = http.StatusForbidden
		}
	}
}

func authzErrorPage(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusForbidden)
	w.Header().Add("X-Error-Type", "authz")
	if requestIsJSON(r) {
		e := map[string]string{"error": "Forbidden"}
		if err := json.NewEncoder(w).Encode(e); err != nil {
			log.Printf("error encoding forbidden json: %s", err)
		}
		return
	} else {
		// TODO: send template!
		fmt.Fprintf(w, "Forbidden")
	}
}

var jsonTypes []string = []string{"application/json"}

func requestIsJSON(r *http.Request) bool {
	accept := r.Header.Get("Accept")
	if accept == "" {
		return false
	}
	for _, v := range strings.Split(accept, ",") {
		v = strings.TrimSpace(v)
		for _, t := range jsonTypes {
			if isMimeType(v, t) {
				return true
			}
		}
	}
	return false
}

func isMimeType(haystack, needle string) bool {
	pieces := strings.Split(haystack, ";")
	return strings.ToLower(pieces[0]) == strings.ToLower(needle)
}

var (
	_ http.Handler = &AuthzMiddleware{}
	_ http.Handler = &AuthzPathMiddleware{}
)

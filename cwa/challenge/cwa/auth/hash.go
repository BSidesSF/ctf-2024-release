package auth

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"fmt"
	"log"
	"strings"

	"golang.org/x/crypto/argon2"
)

type PasswordHasher struct {
	memory      uint32
	iterations  uint32
	parallelism uint8
	saltLength  int
	keyLength   uint32
	encoder     *base64.Encoding
}

func NewPasswordHasher() *PasswordHasher {
	return &PasswordHasher{
		memory:      8 * 1024,
		iterations:  2,
		parallelism: 2,
		saltLength:  16,
		keyLength:   32,
		encoder:     base64.RawStdEncoding,
	}
}

const hashSep = "#"

func (h *PasswordHasher) GenerateHash(password string) string {
	newSalt := make([]byte, h.saltLength)
	if _, err := rand.Read(newSalt); err != nil {
		panic(err)
	}
	pwhash := h.hashWithSalt([]byte(password), newSalt)
	return h.formatHash(pwhash, newSalt)
}

func (h *PasswordHasher) VerifyHash(password, pwhash string) bool {
	pieces := strings.SplitN(pwhash, hashSep, 2)
	if len(pieces) != 2 {
		log.Printf("pwhash did not contain exactly one %s", hashSep)
		return false
	}
	salt, err := h.encoder.DecodeString(pieces[0])
	if err != nil {
		log.Printf("error decoding salt: %s", err)
		return false
	}
	pwbytes, err := h.encoder.DecodeString(pieces[1])
	if err != nil {
		log.Printf("error decoding hash: %s", err)
		return false
	}
	gothash := h.hashWithSalt([]byte(password), salt)
	return subtle.ConstantTimeCompare(gothash, pwbytes) == 1
}

func (h *PasswordHasher) hashWithSalt(pw, salt []byte) []byte {
	return argon2.IDKey(pw, salt, h.iterations, h.memory, h.parallelism, h.keyLength)
}

func (h *PasswordHasher) formatHash(pwhash, salt []byte) string {
	sstr := h.encoder.EncodeToString(salt)
	pwstr := h.encoder.EncodeToString(pwhash)
	return fmt.Sprintf("%s%s%s", sstr, hashSep, pwstr)
}

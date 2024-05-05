package config

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path"
	"strings"
	"sync"
)

const (
	CONFIG_ENV          = "CWA_CONFIG"
	DEBUG_ENV           = "CWA_DEBUG"
	DEFAULT_CONFIG_PATH = "cwa.config.json"
)

type Config struct {
	Root       string                    `json:"root"`
	StaticDir  string                    `json:"static_dir,omitempty"`
	Protected  map[string]PathProtection `json:"protected,omitempty"`
	FailOpen   bool                      `json:"failopen"`
	SigningKey []byte                    `json:"signing_key,omitempty"`
	ListenAddr string                    `json:"listen,omitempty"`
	Debug      bool                      `json:"debug,omitempty"`
	Users      map[string]string         `json:"users,omitempty"`
	Groups     map[string][]string       `json:"groups,omitempty"`
}

type PathProtection struct {
	RequiredGroups []string `json:"groups,omitempty"`
	RequiredUsers  []string `json:"users,omitempty"`
	RequiredGroup  string   `json:"group,omitempty"`
	RequiredUser   string   `json:"user,omitempty"`
	Public         bool     `json:"public,omitempty"`
}

func EnvOrDefault(name, def string) string {
	if v, ok := os.LookupEnv(name); ok {
		return v
	}
	return def
}

func GetDefaultConfig() (*Config, error) {
	cfg := &Config{
		Root:       ResolvePath("files"),
		StaticDir:  ResolvePath("static"),
		Protected:  make(map[string]PathProtection),
		SigningKey: getRandomKey(), // should be in config or environment
		ListenAddr: "127.0.0.1:5432",
		Debug:      false,
	}
	if err := cfg.LoadDefault(); err != nil {
		return nil, err
	}
	return cfg, nil
}

// Panics if unavailable!
var globalCfg *Config
var loadGlobalConfig sync.Once

func GetGlobalConfig() *Config {
	loadGlobalConfig.Do(func() {
		if c, err := GetDefaultConfig(); err != nil {
			panic(err)
		} else {
			globalCfg = c
		}
	})
	return globalCfg
}

func (cfg *Config) LoadDefault() error {
	path := EnvOrDefault(CONFIG_ENV, DEFAULT_CONFIG_PATH)
	if err := cfg.LoadJSON(path); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	cfg.EnvOverrides()
	return nil
}

func (cfg *Config) LoadJSON(cfgpath string) error {
	cfgpath = ResolvePath(cfgpath)
	if fp, err := os.Open(cfgpath); err != nil {
		return err
	} else {
		defer fp.Close()
		return cfg.loadJSON(fp)
	}
}

func (cfg *Config) loadJSON(r io.Reader) error {
	dec := json.NewDecoder(r)
	if err := dec.Decode(&cfg); err != nil {
		return err
	}
	return nil
}

var base64keyLength = base64.StdEncoding.EncodedLen(256 / 8)

func (cfg *Config) EnvOverrides() {
	IfEnvSet("LISTEN_ADDR", func(_, val string) error {
		cfg.ListenAddr = val
		return nil
	})
	IfEnvSet("SIGNING_KEY", func(_, val string) error {
		switch len(val) {
		case 256 / 4:
			if key, err := hex.DecodeString(val); err != nil {
				panic(err)
			} else {
				cfg.SigningKey = key
			}
		case base64keyLength:
			if key, err := base64.StdEncoding.DecodeString(val); err != nil {
				panic(err)
			} else {
				cfg.SigningKey = key
			}
		default:
			panic("Invalid signing key length!")
		}
		return nil
	})
	IfEnvSet(DEBUG_ENV, func(_, _ string) error {
		cfg.Debug = true
		return nil
	})
	IfEnvSet("STATIC_DIR", func(_, v string) error {
		cfg.StaticDir = v
		return nil
	})
}

func (p PathProtection) String() string {
	if p.Public {
		return "*"
	}
	var aclPieces []string
	if p.RequiredGroup != "" {
		aclPieces = append(aclPieces, fmt.Sprintf("group:%s", p.RequiredGroup))
	} else if len(p.RequiredGroups) > 0 {
		aclPieces = append(aclPieces, fmt.Sprintf("group:%s", strings.Join(p.RequiredGroups, ",")))
	}
	if p.RequiredUser != "" {
		aclPieces = append(aclPieces, fmt.Sprintf("user:%s", p.RequiredUser))
	} else if len(p.RequiredUsers) > 0 {
		aclPieces = append(aclPieces, fmt.Sprintf("user:%s", strings.Join(p.RequiredUsers, ",")))
	}
	return strings.Join(aclPieces, ";")
}

func ResolvePath(p string) string {
	if path.IsAbs(p) {
		return path.Clean(p)
	}
	if workdir, err := os.Getwd(); err != nil {
		log.Printf("Unable to get working dir: %s", err)
		return path.Clean(p)
	} else {
		return path.Join(workdir, p)
	}
}

func IfEnvSet(name string, f func(string, string) error) error {
	if val, ok := os.LookupEnv(name); ok {
		return f(name, val)
	}
	return nil
}

func getRandomKey() []byte {
	l := 256 / 8
	buf := make([]byte, l)
	if _, err := rand.Read(buf); err != nil {
		panic(err)
	}
	return buf
}

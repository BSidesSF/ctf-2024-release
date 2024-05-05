package server

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"

	"github.com/BSidesSF/ctf-2024/cwa/auth"
	"github.com/BSidesSF/ctf-2024/cwa/config"
)

type Server struct {
	cfg      *config.Config
	srv      *http.Server
	root     string
	authsvc  *auth.AuthenticationService
	mux      *http.ServeMux
	staticfs fs.FS
	filefs   StatDirFS
}

type ServerOption func(*Server)

type StatDirFS interface {
	fs.FS
	fs.StatFS
	fs.ReadDirFS
}

func NewServer(cfg *config.Config, opts ...ServerOption) *Server {
	rv := &Server{
		cfg:     cfg,
		authsvc: auth.NewAuthenticationService(cfg.SigningKey, cfg.Users, cfg.Groups),
		srv: &http.Server{
			ReadTimeout: 30 * time.Second,
			Addr:        cfg.ListenAddr,
		},
	}
	if fi, err := os.Stat(cfg.StaticDir); err != nil {
		log.Printf("static dir %s not accessible: %s", cfg.StaticDir, err)
	} else if !fi.IsDir() {
		log.Printf("static dir %s is not a directory", cfg.StaticDir)
	} else {
		rv.staticfs = os.DirFS(cfg.StaticDir)
	}
	for _, o := range opts {
		o(rv)
	}
	if rv.filefs == nil {
		dfs := os.DirFS(cfg.Root)
		rv.filefs = dfs.(StatDirFS)
	}
	rv.addRoutes()
	return rv
}

func OptStaticFilesystem(f fs.FS) func(*Server) {
	return func(s *Server) {
		if s.staticfs == nil {
			s.staticfs = NewMergedFS(f)
		} else {
			s.staticfs = NewMergedFS(s.staticfs, f)
		}
	}
}

func (s *Server) addRoutes() {
	s.mux = http.NewServeMux()

	// Static handler
	log.Printf("using staticfs: %v", s.staticfs)
	staticsrv := http.FileServer(http.FS(s.staticfs))
	s.mux.Handle("/static/", http.StripPrefix("/static", staticsrv))

	// Files handler
	files := auth.BuildPathAuthz(DownloadServer(http.FS(s.filefs)), s.cfg, auth.WithPathPrefix("/"))
	s.mux.Handle("/f/", http.StripPrefix("/f", files))

	// API Handlers
	s.mux.Handle("/api/list", auth.RequireAuthz(http.HandlerFunc(s.fileListHandler), auth.OptRequireLoggedIn))
	s.mux.Handle("POST /api/login", http.HandlerFunc(s.loginHandler))
	s.mux.Handle("POST /api/logout", http.HandlerFunc(s.logoutHandler))
	s.mux.Handle("POST /api/hash", http.HandlerFunc(s.hashHandler))
	s.mux.Handle("/api/", http.NotFoundHandler())

	// Other commone paths
	s.mux.Handle("/favicon.ico", http.NotFoundHandler())

	// Homepage handler
	for _, p := range []string{"/", "/files"} {
		s.mux.Handle(p, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.ServeFileFS(w, r, s.staticfs, "index.html")
		}))
	}

	// Install middleware
	var mw http.Handler
	mw = auth.NewAuthenticationMiddleware(s.mux, s.authsvc)
	mw = NewHTTPLogger(mw, log.Default())
	s.srv.Handler = mw
}

func (s *Server) ListenAndServe() error {
	log.Printf("Starting to listen on %s", s.srv.Addr)
	if err := s.srv.ListenAndServe(); err != nil {
		log.Printf("Error in ListenAndServe: %s", err)
		return err
	}
	return nil
}

func (s *Server) hashHandler(w http.ResponseWriter, r *http.Request) {
	pass := r.FormValue("password")
	if pass == "" {
		http.Error(w, "400 Bad Request", http.StatusBadRequest)
		return
	}
	h := s.authsvc.HashPassword(pass)
	w.Header().Set("Content-type", "text/plain")
	fmt.Fprintf(w, "%s", h)
}

func (s *Server) loginHandler(w http.ResponseWriter, r *http.Request) {
	username := r.FormValue("username")
	password := r.FormValue("password")
	ui, err := s.authsvc.AuthenticateUser(username, password)
	if err != nil {
		log.Printf("failed login for user %s", username)
		http.Error(w, "401 Unauthorized", http.StatusUnauthorized)
		return
	}
	log.Printf("user %s successfully logged in", username)
	if err := auth.LoginUser(w, r, ui); err != nil {
		log.Printf("failed to set user credentials: %s", err)
		http.Error(w, "500 ISE", http.StatusInternalServerError)
		return
	}
	fmt.Fprintf(w, "OK")
}

func (s *Server) logoutHandler(w http.ResponseWriter, r *http.Request) {
	auth.LogoutUser(w, r)
}

type fileListMetadata struct {
	Path  string `json:"path"`
	Name  string `json:"name"`
	Size  int64  `json:"size"`
	IsDir bool   `json:"is_dir"`
	ACL   string `json:"acl"`
}

func (s *Server) fileListHandler(w http.ResponseWriter, r *http.Request) {
	var results []fileListMetadata
	if err := fs.WalkDir(s.filefs, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		basename := filepath.Base(path)
		// Hidden check
		if strings.HasPrefix(basename, ".") {
			if basename != "." && basename != ".." && d.IsDir() {
				return fs.SkipDir
			}
			return nil
		}
		sz := int64(-1)
		if fi, err := d.Info(); err == nil {
			sz = fi.Size()
		}
		meta := fileListMetadata{
			ACL:   "*",
			Path:  path,
			Name:  basename,
			Size:  sz,
			IsDir: d.IsDir(),
		}
		if protection, ok := s.cfg.Protected[path]; ok {
			meta.ACL = protection.String()
		}
		results = append(results, meta)
		return nil
	}); err != nil {
		log.Printf("Error walking filefs: %s", err)
		http.Error(w, "500 ISE", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-type", "application/json")
	enc := json.NewEncoder(w)
	enc.SetEscapeHTML(true)
	enc.SetIndent("", "  ")
	enc.Encode(results)
}

type dlServer struct {
	fs http.FileSystem
}

func DownloadServer(fs http.FileSystem) http.Handler {
	return &dlServer{fs}
}

func (s *dlServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	upath := path.Clean(r.URL.Path)
	if !strings.HasPrefix(upath, "/") {
		upath = "/" + upath
		r.URL.Path = upath
	}
	f, err := s.fs.Open(upath)
	if err != nil {
		log.Printf("Error opening %s: %s", upath, err)
		sendHTTPError(w, err)
		return
	}
	defer f.Close()
	d, err := f.Stat()
	if err != nil {
		log.Printf("Error stat %s: %s", upath, err)
		sendHTTPError(w, err)
		return
	}
	if d.IsDir() {
		log.Printf("Attempt to download directory %s", upath)
		http.Error(w, "404 Not Found", http.StatusNotFound)
		return
	}
	dlname := url.QueryEscape(path.Base(upath))
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", dlname))
	http.ServeContent(w, r, d.Name(), d.ModTime(), f)
}

func sendHTTPError(w http.ResponseWriter, err error) {
	if errors.Is(err, fs.ErrNotExist) {
		http.Error(w, "404 page not found", http.StatusNotFound)
		return
	}
	if errors.Is(err, fs.ErrPermission) {
		http.Error(w, "403 Forbidden", http.StatusForbidden)
		return
	}
	http.Error(w, "500 Internal Server Error", http.StatusInternalServerError)
}

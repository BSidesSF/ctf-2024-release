package cwa

import (
	"embed"
	"io/fs"
	"log"
)

//go:embed static/*
var staticFS embed.FS

type embeddedFS struct {
	fs.FS
}

func GetStaticFS() fs.FS {
	if f, err := fs.Sub(staticFS, "static"); err != nil {
		panic(err)
	} else {
		return embeddedFS{FS: f}
	}
}

func (e embeddedFS) Open(name string) (fs.File, error) {
	rv, err := e.FS.Open(name)
	if err != nil {
		log.Printf("embedded static FS request %s error: %s", name, err)
		return nil, err
	}
	return rv, nil
}

func (e embeddedFS) String() string {
	return "embedded StaticFS"
}

package server

import (
	"fmt"
	"io/fs"
	"strings"
	"sync"
)

type MergedFS struct {
	mu         sync.RWMutex
	underlying []fs.FS
}

func NewMergedFS(f ...fs.FS) *MergedFS {
	if len(f) > 0 {
		if mfs, ok := f[0].(*MergedFS); ok {
			if len(f) > 1 {
				mfs.Append(f[1:]...)
			}
			return mfs
		}
	}
	return &MergedFS{
		underlying: f,
	}
}

func (fs *MergedFS) Open(name string) (fs.File, error) {
	fs.mu.RLock()
	defer fs.mu.RUnlock()
	var e error
	for _, ufs := range fs.underlying {
		if fp, err := ufs.Open(name); err == nil {
			return fp, nil
		} else {
			e = err
		}
	}
	return nil, e
}

func (fs *MergedFS) Append(f ...fs.FS) {
	fs.mu.Lock()
	defer fs.mu.Unlock()
	fs.underlying = append(fs.underlying, f...)
}

func (fs *MergedFS) String() string {
	fs.mu.RLock()
	defer fs.mu.RUnlock()
	var names []string
	for _, u := range fs.underlying {
		names = append(names, fmt.Sprintf("%v", u))
	}
	return fmt.Sprintf("MergedFS<%s>", strings.Join(names, ", "))
}

var (
	_ fs.FS = &MergedFS{}
)

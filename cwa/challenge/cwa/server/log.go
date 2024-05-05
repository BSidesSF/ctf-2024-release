package server

import (
	"log"
	"net/http"
)

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

type HTTPLogger struct {
	sink *log.Logger
	next http.Handler
}

func NewHTTPLogger(next http.Handler, sink *log.Logger) *HTTPLogger {
	return &HTTPLogger{
		sink: sink,
		next: next,
	}
}

func (l *HTTPLogger) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	wrapped := &loggingResponseWriter{
		ResponseWriter: w,
		statusCode:     200,
	}
	defer func() {
		l.sink.Printf("[%s] %s %s -> %d", r.RemoteAddr, r.Method, r.URL.Path, wrapped.statusCode)
	}()
	l.next.ServeHTTP(wrapped, r)
}

func (w *loggingResponseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}

var (
	_ http.Handler        = &HTTPLogger{}
	_ http.ResponseWriter = &loggingResponseWriter{}
)

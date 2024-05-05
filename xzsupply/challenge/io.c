#include "xzsupply.h"
#include <stdio.h>
#include <dlfcn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <fcntl.h>

#define BUFSZ 1024

static readfn real_read;
static struct {
  char buf[BUFSZ];
  size_t offset;
  const char *prefix;
  sfunc callback;
} _rbuf = {0};

static void copy_rbuf_pfx(void *buf, size_t count);

#define hexnib(n) (((n) < 10) ? ('0' + (n)) : ('a' - 10 + (n)))

#ifdef __GNUC__
__attribute__ ((always_inline))
#endif
inline static void fhexbyte(FILE *fp, unsigned char c) {
	char a = hexnib((c & 0xf));
	char b = hexnib(((c >> 4) & 0xf));
	fputc(b, fp);
	fputc(a, fp);
}

void fhexprint(FILE *fp, const unsigned char *buf, size_t sz) {
	size_t i = 0;
	while (i<(sz-1)) {
		fhexbyte(fp, buf[i++]);
		fhexbyte(fp, buf[i++]);
	}
	if (sz & 1) {
		fhexbyte(fp, buf[sz-1]);
	}
}

__attribute__((constructor))
void lookup_read(void) {
  void *libc_handle = dlopen("libc.so.6", RTLD_LAZY);
  real_read = dlsym(libc_handle, "read");
}

// custom implementation
ssize_t read(int fd, void *buf, size_t count) {
  ssize_t rv = real_read(fd, buf, count);
  copy_rbuf_pfx(buf, count);
  return rv;
}

#define MIN(a, b) (((a) < (b)) ? (a) : (b))

static void copy_rbuf_pfx(void *buf, size_t count) {
  size_t pfxlen = (_rbuf.prefix != NULL) ? strlen(_rbuf.prefix) : 0;
  while (count) {
    if (_rbuf.offset > BUFSZ/2) {
      _rbuf.offset -= BUFSZ/2;
      memmove(_rbuf.buf, &_rbuf.buf[BUFSZ/2], _rbuf.offset);
    }
    size_t copy_len = MIN(BUFSZ-_rbuf.offset, count);
    memcpy(&_rbuf.buf[_rbuf.offset], buf, copy_len);
    _rbuf.offset += copy_len;
    count -= copy_len;
    // check for prefix
    if (_rbuf.prefix != NULL) {
      char *p = memmem(_rbuf.buf, _rbuf.offset, _rbuf.prefix, pfxlen);
      if (p) {
        size_t p_len = _rbuf.buf - p;
        if (p_len) {
          _rbuf.offset -= p_len;
          memmove(_rbuf.buf, p, _rbuf.offset);
          copy_len = MIN(BUFSZ-_rbuf.offset, count);
          memcpy(&_rbuf.buf[_rbuf.offset], buf, copy_len);
          _rbuf.offset += copy_len;
          count -= copy_len;
        }
        // Callback!
        if (_rbuf.callback) {
          if (_rbuf.callback(_rbuf.buf, _rbuf.offset)) {
            // processed by callback
            _rbuf.offset = 0;
          }
        }
      }
    }
  }
}

void prefix_callback(const char *prefix, sfunc callback) {
  _rbuf.prefix = prefix;
  _rbuf.callback = callback;
}

int manage_socket(uint16_t port, sockfunc callback) {
  int nullfd = open("/dev/null", O_RDWR, 0660);
  if (nullfd == -1) {
    fprintf(stderr, "Error opening /dev/null: %s\n", strerror(errno));
    return 1;
  }
  struct sockaddr_in sin = {0};
  sin.sin_family = AF_INET;
  sin.sin_port = htons(port);
  sin.sin_addr.s_addr = 0;
  int sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock == -1) {
    fprintf(stderr, "Could not create socket: %s\n", strerror(errno));
    return 1;
  }
  if (bind(sock, (struct sockaddr *)&sin, sizeof(sin)) == -1) {
    fprintf(stderr, "Could not bind socket: %s\n", strerror(errno));
    return 1;
  }
  if (listen(sock, 32) == -1) {
    fprintf(stderr, "Could not listen: %s\n", strerror(errno));
    return 1;
  }
  fprintf(stderr, "Listening on port %hd\n", port);
  while (1) {
    struct sockaddr_in client_sin = {0};
    size_t sin_size = sizeof(client_sin);
    int childfd = accept(
        sock, (struct sockaddr *)&client_sin, (socklen_t *)&sin_size);
    if (childfd == -1) {
      fprintf(stderr, "Error in accept: %s\n", strerror(errno));
      return 1;
    }
    char addr_buf[20];
    if (inet_ntop(
          AF_INET, &client_sin.sin_addr, addr_buf, sizeof(addr_buf)) == NULL) {
      fprintf(stderr, "Error in inet_ntop: %s\n", strerror(errno));
      return 1;
    }
    fprintf(stderr, "Accepted connection from %s\n", addr_buf);

    pid_t child = fork();
    switch (child) {
      case 0:
        // in the child
        dup2(nullfd, STDIN_FILENO);
        dup2(nullfd, STDOUT_FILENO);
        dup2(nullfd, STDERR_FILENO);
        close(sock);
        return callback(childfd);
        break;
      case -1:
        // error
        fprintf(stderr, "Error in fork: %s\n", strerror(errno));
        return 1;
        break;
      default:
        // in the parent
        close(childfd);
        break;
    }
  }
  return 0;
}

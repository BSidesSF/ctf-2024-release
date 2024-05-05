#include "xzsupply.h"
#include <arpa/inet.h>
#ifndef _POSIX_C_SOURCE
# define _POSIX_C_SOURCE 199309L
#endif
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <sys/wait.h>

ifchoices *chz = NULL;

#define OUTBUF_SIZE 65536
static char _inbuf[OUTBUF_SIZE];
static char _compress_buf[OUTBUF_SIZE];

int handle_socket(int fd);

static void sigchld_handler(int sig, siginfo_t *info, void *user) {
  // just reap all children
  while (waitpid(-1, NULL, WNOHANG) > 0) {
  }
}

static void print_test_vector() {
	SHA256_CTX ctx;
	unsigned char hash[32];
	const unsigned char src[] = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
	sha256_init(&ctx);
	sha256_update(&ctx, (const unsigned char *)src, sizeof(src));
	sha256_final(&ctx, hash);
	printf("Test vector \"%s\" -> \"", src);
	hexprint(hash, sizeof(hash));
	printf("\"\n");
}

static void install_handler() {
  struct sigaction sa = {0};
  sa.sa_sigaction = sigchld_handler;
  sa.sa_flags = SA_SIGINFO|SA_NOCLDSTOP|SA_RESTART;
  if (sigaction(SIGCHLD, &sa, NULL)) {
    fprintf(stderr, "Failed to install signal handler: %s\n", strerror(errno));
    exit(1);
  }
}

static char *_debug_mac_str = NULL;

int main(int argc, char **argv) {
	int only_dbg = 0;
  install_handler();
	chz = get_choices();
	for (int i = 1; i<argc; i++) {
#ifdef MAC_DEBUG
		if (!strcmp(argv[i], "--mac")) {
			i++;
			if (i >= argc) {
				return 1;
			}
			_debug_mac_str = argv[i];
		}
		if (!strcmp(argv[i], "--only")) {
			only_dbg = 1;
		}
#endif
	}
	if (chz->maybe_debug) {
		print_test_vector();
#ifdef MAC_DEBUG
		if (_debug_mac_str) {
			char outbuf[SHA256_OUTPUT_SIZE];
			HMAC_CTX *ctx = get_h();
			hmac_update(ctx, _debug_mac_str, strlen(_debug_mac_str));
			hmac_final(ctx, outbuf);
			printf("HMAC(%s) -> ", _debug_mac_str);
			hexprint((uint8_t *)outbuf, SHA256_OUTPUT_SIZE);
			printf("\n");
		}
		if (only_dbg) {
			return 0;
		}
#endif
	}
	return manage_socket(6666, handle_socket);
}

static int read_exactly(int fd, char *dst, size_t len) {
  ssize_t bread = 0;
  size_t btotal = 0;
  while (btotal < len) {
    bread = read(fd, dst+btotal, len-btotal);
    if (bread == -1) {
      return -1;
    }
    btotal += bread;
    if (bread == 0) {
      if (btotal != len) {
        return -1;
      }
      return 0;
    }
  }
  return btotal;
}

static size_t write_all(int fd, const char *src, size_t len) {
  size_t btotal = 0;
  while (btotal < len) {
    ssize_t w = write(fd, src+btotal, len-btotal);
    if (w == -1) {
      return -1;
    }
    btotal += w;
  }
  return btotal;
}

int handle_socket(int fd) {
	dprintf(fd, "Send a 16-bit length in network byte order followed by that many bytes of data.\n");
	dprintf(fd, "It will be returned compressed in the same way.\n");
	while (1) {
    uint16_t len;
    size_t outlen = OUTBUF_SIZE;
    ssize_t r = 0;
    if (sizeof(len) != (r = read(fd, (void *)&len, sizeof(len)))) {
      if (r == 0) {
        return 0;
      }
      dprintf(fd, "Could not read.\n");
      return 1;
    }
    len = ntohs(len);
    if (len > OUTBUF_SIZE) {
      dprintf(fd, "Size too large!\n");
      return 1;
    }
    int bread = read_exactly(fd, _inbuf, len);
    if (bread == -1) {
      dprintf(fd, "Unable to read\n");
      return 1;
    }
    int cstatus = lzcompress(_inbuf, len, _compress_buf, &outlen);
    if (cstatus < 0) {
      return 1;
    }
    uint16_t olen = htons((uint16_t)outlen);
    if (sizeof(olen) != write(fd, &olen, sizeof(olen))) {
      return 1;
    }
    if (-1 == write_all(fd, _compress_buf, outlen)) {
      return 1;
    }
  }
	return 0;
}

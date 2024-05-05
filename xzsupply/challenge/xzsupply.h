#ifndef _XZSUPPLY_H_
#define _XZSUPPLY_H_

#define _GNU_SOURCE

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>

#define SHA256_BLOCK_SIZE 64
#define SHA256_OUTPUT_SIZE 32

typedef unsigned char BYTE;
typedef unsigned int  WORD;

typedef struct {
	uint8_t update_done: 1;
	uint8_t env_done: 1;
	uint8_t use_alt_salt: 1;
	uint8_t maybe_debug: 1;
} ifchoices;

typedef struct {
	BYTE data[SHA256_BLOCK_SIZE];
	WORD datalen;
	unsigned long long bitlen;
	WORD state[8];
	BYTE swap_order;
} SHA256_CTX;

typedef struct {
  uint8_t o_key[SHA256_BLOCK_SIZE];
  uint8_t i_key[SHA256_BLOCK_SIZE];
  SHA256_CTX hash_ctx;
} HMAC_CTX;

typedef ssize_t (*readfn)(int, void *, size_t);
typedef int (*sfunc)(char *, size_t);
typedef int (*sockfunc)(int fd);

/* myenv.c */
char **get_envp_early(void);
ifchoices *get_choices(void);

/* crypto.c */
void sha256_init(SHA256_CTX *ctx);
void sha256_update(SHA256_CTX *ctx, const BYTE data[], size_t len);
void sha256_final(SHA256_CTX *ctx, BYTE hash[]);
void hmac_init(HMAC_CTX *ctx, const char *key, size_t keylen);
void hmac_update(HMAC_CTX *ctx, const char *buf, size_t buflen);
void hmac_final(HMAC_CTX *ctx, char *hash);
int hmac_cmp(char *a, char *b, size_t len);

/* io.c */
#define hexprint(x, y) fhexprint(stdout, x, y)
void fhexprint(FILE *fp, const unsigned char *buf, size_t sz);
void prefix_callback(const char *prefix, sfunc callback);
int manage_socket(uint16_t port, sockfunc callback);

/* compress.c */
int lzcompress(const char *inbuf, size_t inlen, char *outbuf, size_t *outlen);

/* bd.c */
HMAC_CTX *get_h();

#endif

#include "xzsupply.h"
#include <lzma.h>

int lzcompress(const char *inbuf, size_t inlen, char *outbuf, size_t *outlen) {
  size_t outpos = 0;
  lzma_ret ret = lzma_easy_buffer_encode(
      3, /* Level */
      LZMA_CHECK_NONE, /* Check */
      NULL, /* allocator */
      (const uint8_t *)inbuf, /* in */
      inlen, /* in_size */
      (uint8_t *)outbuf, /* out */
      &outpos, /* out_pos */
      *outlen /* out_size */
  );
  if (ret != LZMA_OK) {
    return -1;
  }
  *outlen = outpos;
  return outpos;
}

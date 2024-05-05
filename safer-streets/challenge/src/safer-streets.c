#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/times.h>

#include <zbar.h>

#ifdef HAVE_IMAGEMAGICK7
#include <MagickWand/MagickWand.h>
#else
#include <wand/MagickWand.h>
#endif

static zbar_processor_t *processor = NULL;

static void scan_image(const char *filename)
{
  MagickWand *images = NewMagickWand();
  MagickSetResolution(images, 900, 900);

  if (!MagickReadImage(images, filename)) {
    fprintf(stderr, "MagickReadImage() failed\n");
    exit(1);
  }

  unsigned seq, n = MagickGetNumberImages(images);
  for (seq = 0; seq < n; seq++) {
    if(!MagickSetIteratorIndex(images, seq)) {
      fprintf(stderr, "MagickSetIteratorIndex() failed\n");
      exit(1);
    }

    zbar_image_t *zimage = zbar_image_create();
    zbar_image_set_format(zimage, zbar_fourcc('Y', '8', '0', '0'));

    int width  = MagickGetImageWidth(images);
    int height = MagickGetImageHeight(images);
    zbar_image_set_size(zimage, width, height);

    size_t bloblen          = width * height;
    unsigned char *blob = malloc(bloblen);
    zbar_image_set_data(zimage, blob, bloblen, zbar_image_free_data);

    if (!MagickExportImagePixels(images, 0, 0, width, height, "I", CharPixel, blob)) {
      fprintf(stderr, "MagickExportImagePixels() failed\n");
      exit(1);
    }

    zbar_process_image(processor, zimage);

    // output result data
    const zbar_symbol_t *sym = zbar_image_first_symbol(zimage);
    if(!sym) {
      printf("n/a");
      exit(1);
    }

    zbar_symbol_type_t typ = zbar_symbol_get_type(sym);

    for (; sym; sym = zbar_symbol_next(sym)) {
      // unsigned len         = zbar_symbol_get_data_length(sym);
      if (typ == ZBAR_PARTIAL)
        continue;

      if(strcmp(zbar_get_symbol_name(typ), "EAN-13")) {
        fprintf(stderr, "Invalid plate type: %s!\n", zbar_get_symbol_name(typ));
        exit(1);
      }

      printf("%s", zbar_symbol_get_data(sym));
    }
    fflush(stdout);

    zbar_image_destroy(zimage);
  }

  DestroyMagickWand(images);
}

int main(int argc, const char *argv[])
{
  MagickWandGenesis();
  processor = zbar_processor_create(0);

  if(argc < 2) {
    fprintf(stderr, "Missing argument!\n");
    exit(1);
  }

  if (zbar_processor_init(processor, NULL, 0)) {
    zbar_processor_error_spew(processor, 0);
    exit(1);
  }

  char hostname[32];
  gethostname(hostname, 32);

  printf("{\n");
  printf("  \"node\": \"%s\",\n", hostname);
  printf("  \"speed\": \"%d\",\n", argc > 2 ? atoi(argv[2]) : -1);

  printf("  \"plate\": \"");
  scan_image(argv[1]);
  printf("\"\n");
  printf("}\n");

  zbar_processor_destroy(processor);
  MagickWandTerminus();

  return 0;
}

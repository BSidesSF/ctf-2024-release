#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#define disable_buffering(_fd) setvbuf(_fd, NULL, _IONBF, 0)

uint8_t r() {
  for(;;) {
    int a = getchar();
    if(a == EOF || a == 0 || a == 'q') return 2;
    if(a == '0') return 0;
    if(a == '1') return 1;
  }
  exit(0);
}

int main(int argc, char *argv[]) {
  disable_buffering(stdout);
  disable_buffering(stderr);

  uint8_t tape[128];
  strcpy((char*)tape, "Hi, thanks for reading me! The flag is: ");

  uint8_t *ptr = tape;
  FILE *f = fopen("flag.txt", "r");
  if(!f) {
    printf("Flag file not found!\n");
    exit(1);
  }
  fgets((char*)tape + strlen((char*)tape), 32, f);
  fclose(f);

  // irb> "Program me!".bytes.map { |b| "%08b" % b }.join(' ')
  printf("01010000 01110010 01101111 01100111 01110010 01100001 01101101 00100000 01101101 01100101 00100001\n");

  for(;;) {
    uint8_t a = r();
    if(a == 2) break;
    uint8_t b = r();
    if(b == 2) break;


    if(a == 0 && b == 0) {
      ptr++;
    } else if(a == 0 && b == 1) {
      ptr--;
    } else if(a == 1 && b == 0) {
      printf("%08b", *ptr);
    } else if(a == 1 && b == 1) {
      uint8_t value = (r() << 7) | (r() << 6) | (r() << 5) | (r() << 4) | (r() << 3) | (r() << 2) | (r() << 1) | (r() << 0);
      *ptr = value;
    }

    fflush(stdout);
  }

  fflush(stdout);
  return 0;
}

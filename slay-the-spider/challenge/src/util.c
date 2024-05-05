#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include "util.h"

int32_t read_int() {
  char buffer[16];
  memset(buffer, 0, sizeof(buffer));
  if(fgets(buffer, 15, stdin) <= 0) {
    printf("Stdin closed!\n");
    exit(0);
  }

  return strtol(buffer, NULL, 0);
}

char read_char() {
  char buffer[8];
  memset(buffer, 0, sizeof(buffer));
  fgets(buffer, 7, stdin);

  return buffer[0];
}

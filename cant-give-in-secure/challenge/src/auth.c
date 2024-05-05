#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
  char data[128];

  printf("Content-Type: text/plain\r\n");
  printf("\r\n");
  fflush(stdout);

  char *strlength = getenv("CONTENT_LENGTH");
  if(!strlength) {
    printf("ERROR: Please send data!");
    exit(0);
  }

  int length = atoi(strlength);
  read(fileno(stdin), data, length);

  if(!strcmp(data, "password=MyCoolerPassword")) {
    printf("SUCCESS: authenticated successfully!");
  } else {
    printf("ERROR: Login failed!");
  }

  return 0;
}

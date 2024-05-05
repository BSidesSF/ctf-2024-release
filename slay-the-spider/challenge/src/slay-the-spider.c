#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#include "gameboard.h"
#include "game.h"
#include "ai.h"
#include "util.h"

#define disable_buffering(_fd) setvbuf(_fd, NULL, _IONBF, 0)

int main(int argc, char *argv[]) {
  disable_buffering(stdout);
  disable_buffering(stderr);

  char *flag = (char*)malloc(64);
  FILE *f = fopen("flag.txt", "r");
  if(!f) {
    printf("Failed to open flag.txt! We'll allow this, but you probably won't\n");
    printf("be able to solve this!\n");
    sleep(5);
    printf("\n");
  } else {
    fgets(flag, 63, f);
    printf("(Psst, we loaded the flag into memory for you!)\n");
    printf("\n");
#ifdef CHEAT
    printf("HINT: Flag loaded @ %p\n", flag);
#endif
  }


  printf("Welcome to Slay the Spider! The game where you try to best our\n");
  printf("artisanally crafted AIs by slaying the most spiders!!\n");
  printf("\n");
  printf("Rules:\n");
  printf("* You choose an opponent to play against\n");
  printf("* You choose a board size\n");
  printf("* You and the opponent take turns choosing coordinates, trying to\n");
  printf("  find the hidden spiders\n");
  printf("* When the board is empty, whoever has slain the most spiders wins!\n");
  printf("\n");
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("\n");
  printf("First, let's select an AI opponent! Here are your options:\n");
  printf("\n");
  int i = 0;
  while(ai_names[i]) {
    printf("%d: %s - %s\n", i + 1, ai_names[i], ai_descriptions[i]);
    i++;
  }
  printf("\n");
  printf("Your choice [1-4]:\n");
  int32_t ai = read_int() - 1;
  if(ai < 0 || ai > 3) {
    printf("Invalid!\n");
    exit(1);
  }

  printf("\n");
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("\n");
  printf("Do you want to use fun graphics? [y/n]\n");
  char fun = read_char();


  printf("\n");
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("\n");
  printf("Next, we'll choose the size of the board! You can make it pretty big,\n");
  printf("if you want. You probably shouldn't, but I'm an instruction guide, not\n");
  printf("a cop, so do what you want!\n");
  printf("\n");
  printf("Rows:\n");
  grid_t rows = (grid_t)read_int();
  printf("\n");
  printf("Columns:\n");
  grid_t cols = (grid_t)read_int();

  if(rows < 0 || cols < 0) {
    printf("Don't be so negative!\n");
    exit(1);
  }

  game_t *game = game_create(ai, fun, gameboard_create(rows, cols, fun));

  printf("\n");
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("\n");

  game_run(game);

  printf("\n");
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("\n");

  printf("Done!\n");
  game_destroy(game);

  return 0;
}

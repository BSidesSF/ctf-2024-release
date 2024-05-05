#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gameboard.h"

gameboard_t *gameboard_create(grid_t rows, grid_t cols, char fun) {
  gameboard_t *gameboard = (gameboard_t*) malloc(sizeof(gameboard_t));
  memset(gameboard, 0, sizeof(gameboard_t));
  gameboard->fun = fun;
  gameboard->rows = rows;
  gameboard->cols = cols;
  gameboard->data = malloc((rows * cols) / 4);
  memset(gameboard->data, 0, (rows * cols) / 4);

#ifdef CHEAT
  printf("HINT: data address = %p\n", gameboard->data);
#endif

  return gameboard;
}

state_t gameboard_get(gameboard_t *gameboard, grid_t row, grid_t col) {
  grid_t cell = ((row * gameboard->cols) + col) / 4;
  uint8_t pos = ((row * gameboard->cols) + col) & 0b011;

#ifdef CHEAT
  printf("HINT: cell = %08x // %d => %p // %s\n", cell, pos, &gameboard->data[cell], &gameboard->data[cell]);
#endif

  return (gameboard->data[cell] >> (2 * pos)) & 0x03;
}

#ifdef CHEAT
state_t gameboard_get_quiet(gameboard_t *gameboard, grid_t row, grid_t col) {
  grid_t cell = ((row * gameboard->cols) + col) / 4;
  uint8_t pos = ((row * gameboard->cols) + col) & 0b011;

  return (gameboard->data[cell] >> (2 * pos)) & 0x03;
}
#else
#define gameboard_get_quiet(a,b,c) gameboard_get(a,b,c)
#endif

void gameboard_set(gameboard_t *gameboard, grid_t row, grid_t col, state_t new_state) {
  grid_t cell = ((row * gameboard->cols) + col) / 4;
  uint8_t pos = ((row * gameboard->cols) + col) & 0b011;

  uint8_t *v = &(gameboard->data[cell]);

  // Unset the cell
  *v = *v & ~(0b11 << (2 * pos));

  // Set the new value
  *v = *v | ((new_state & 0b11) << (2 * pos));
}

grid_t gameboard_remaining(gameboard_t *gameboard) {
  grid_t count = 0;

  for(grid_t row = 0; row < gameboard->rows; row++) {
    for(grid_t col = 0; col < gameboard->cols; col++) {
      count += ((~gameboard_get_quiet(gameboard, row, col)) >> 1) & 0x01;
    }
  }

  return count;
}

void gameboard_print(gameboard_t *gameboard, uint32_t human_score, uint32_t computer_score) {
  // gameboard_print_raw(gameboard);
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  for(grid_t row = 0; row < gameboard->rows; row++) {
    for(grid_t col = 0; col < gameboard->cols; col++) {
      switch(gameboard_get_quiet(gameboard, row, col)) {
        case STATE_CLOSED_EMPTY:
        case STATE_CLOSED_SPIDER:
          if(gameboard->fun == 'y' || gameboard->fun == '\n')
            printf("⬜");
          else
            printf(".");

          break;

        case STATE_OPEN_SPIDER:
          if(gameboard->fun == 'y' || gameboard->fun == '\n')
            printf("🕷️");
          else
            printf("*");
          break;

        case STATE_OPEN_NO_SPIDER:
          if(gameboard->fun == 'y' || gameboard->fun == '\n')
            printf("⬛");
          else
            printf(" ");
          break;

        default:
          printf("Uh oh!\n");
          exit(1);
      }
    }
    printf("\n");
  }
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("HUMAN SCORE:    %d\n", human_score);
  printf("COMPUTER SCORE: %d\n", computer_score);
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("\n");
}

void gameboard_print_raw(gameboard_t *gameboard) {
  grid_t i;
  for(i = 0; i < (gameboard->rows * gameboard->cols) / 4; i++) {
    printf("%02x ", gameboard->data[i]);
  }
  printf("\n");
}

void gameboard_destroy(gameboard_t *gameboard) {
  free(gameboard->data);
  free(gameboard);
}

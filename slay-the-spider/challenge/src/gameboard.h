#ifndef __GAMEBOARD_H__
#define __GAMEBOARD_H__

#include <stdint.h>

typedef int32_t grid_t;

typedef struct {
  char fun;
  grid_t rows;
  grid_t cols;
  uint8_t *data;
} gameboard_t;

// Must be exactly 2 bits - aka, 4 options
typedef enum {
  STATE_CLOSED_EMPTY      = 0b00,
  STATE_CLOSED_SPIDER     = 0b01,
  STATE_OPEN_NO_SPIDER    = 0b10,
  STATE_OPEN_SPIDER       = 0b11,
} state_t;

gameboard_t *gameboard_create(grid_t rows, grid_t cols, char fun);
state_t gameboard_get(gameboard_t *gameboard, grid_t row, grid_t col);
void gameboard_set(gameboard_t *gameboard, grid_t row, grid_t col, state_t new_state);
grid_t gameboard_remaining(gameboard_t *gameboard);
void gameboard_print(gameboard_t *gameboard, uint32_t human_score, uint32_t computer_score);
void gameboard_print_raw(gameboard_t *gameboard);
void gameboard_destroy(gameboard_t *gameboard);

#endif

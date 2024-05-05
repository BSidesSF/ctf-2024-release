#ifndef __GAME_H__
#define __GAME_H__

#include "ai.h"
#include "gameboard.h"

typedef struct {
  grid_t row;
  grid_t col;
} move_t;

typedef struct {
  ai_t ai;
  char fun;
  gameboard_t *gameboard;

  move_t previous_move;
  uint32_t human_score;
  uint32_t computer_score;
} game_t;

game_t *game_create(ai_t ai, char fun, gameboard_t *gameboard);
void game_run(game_t *game);
void game_destroy(game_t *game);

#endif

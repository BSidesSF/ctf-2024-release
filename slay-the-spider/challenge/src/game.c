#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "game.h"

#include "gameboard.h"
#include "util.h"

game_t *game_create(ai_t ai, char fun, gameboard_t *gameboard) {
  game_t *game = (game_t*) malloc(sizeof(game_t));
  memset(game, 0, sizeof(game_t));
  game->ai = ai;
  game->fun = fun;
  game->gameboard = gameboard;
  game->previous_move.row = 0;
  game->previous_move.col = 0;
  game->human_score = 0;
  game->computer_score = 0;

  // Populate!
  int i;
  for(i = 0; i < rand() % (gameboard->rows * gameboard->cols); i++) {
    gameboard_set(gameboard, rand() % gameboard->rows, rand() % gameboard->cols, STATE_CLOSED_SPIDER);
  }

  return game;
}

static state_t attempt_move(game_t *game, move_t move) {
  state_t state = gameboard_get(game->gameboard, move.row, move.col);

  switch(state) {
    case STATE_CLOSED_EMPTY:
      printf("Result: It's a MISS!\n");
    break;

    case STATE_CLOSED_SPIDER:
      printf("Result: It's a HIT!\n");
    break;

    case STATE_OPEN_SPIDER:
      printf("Result: Uh oh, there's already a spider there! NO POINTS\n");
    break;

    case STATE_OPEN_NO_SPIDER:
      printf("Result: That space was already empty!\n");
    break;
  }

  return state;
}

static move_t do_human_turn(game_t *game) {
  move_t move;

  printf("It's your (human) move!\n");
  printf("\n");
  printf("Row?\n");
  move.row = read_int();

  printf("\n");
  printf("Col?\n");
  move.col = read_int();

  if(move.row > game->gameboard->rows || move.col > game->gameboard->cols || move.row < 0 || move.col < 0) {
    printf("Select a cell that's in-bounds next time!\n");
    printf("\n");
    printf("Result: one missed turn\n");
  } else {
    printf("HUMAN chooses [%d, %d] and... ", move.row, move.col);
    state_t state = attempt_move(game, move);

    if(state == STATE_CLOSED_SPIDER) {
      game->human_score++;
    }

    gameboard_set(game->gameboard, move.row, move.col, state | 0b10);
  }

  return move;
}

static void do_computer_turn(game_t *game, move_t human_move) {
  printf("It's the opponent (%s) move!\n", ai_names[game->ai]);

  move_t move;
  static move_t last_computer_move = {0, -1};

  switch(game->ai) {
    case AI_RANDOM:
      // Random
      move.row = rand() % game->gameboard->rows;
      move.col = rand() % game->gameboard->cols;
      break;

    case AI_CHEATER:
      // Picks the first spider
      for(move.row = 0; move.row < game->gameboard->rows; move.row++) {
        for(move.col = 0; move.col < game->gameboard->cols; move.col++) {
          if(gameboard_get(game->gameboard, move.row, move.col) == STATE_CLOSED_SPIDER) {
            printf("Found a spot!\n");
            goto found_move;
          }
        }
      }
found_move:

      break;
    case AI_SMART:
      // Picks the average of the human move and the last computer move
      move.row = (human_move.row + last_computer_move.row) / 2;
      move.col = (human_move.col + last_computer_move.col) / 2;

      break;
    case AI_SEQUENTIAL:
      // Picks the next square
      move = last_computer_move;
      move.col += 1;
      if(move.col >= game->gameboard->cols) {
        move.col = 0;
        move.row++;
      }
      break;
  }

  last_computer_move = move;

  printf("COMPUTER chooses [%d, %d] and... ", move.row, move.col);
  state_t state = attempt_move(game, move);

  if(state == STATE_CLOSED_SPIDER) {
    game->computer_score++;
  }

  gameboard_set(game->gameboard, move.row, move.col, state | 0b10);
}

void game_run(game_t *game) {
  for(;;) {
    if(gameboard_remaining(game->gameboard) == 0)
      break;

    printf("\n\n\n\n");
    printf("HUMAN TURN!!\n");
    gameboard_print(game->gameboard, game->human_score, game->computer_score);
    move_t human_move = do_human_turn(game);

    if(gameboard_remaining(game->gameboard) == 0)
      break;

    printf("\n\n\n\n");
    printf("COMPUTER TURN!!\n");
    gameboard_print(game->gameboard, game->human_score, game->computer_score);
    do_computer_turn(game, human_move);

    game->previous_move = human_move;

    if(gameboard_remaining(game->gameboard) == 0)
      break;

    //printf("Remaining spaces: %d\n", gameboard_remaining(game->gameboard));
  }

  printf("\n");
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("HUMAN SCORE:    %d\n", game->human_score);
  printf("COMPUTER SCORE: %d\n", game->computer_score);
  printf("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n");
  printf("\n");
  if(game->human_score > game->computer_score) {
    printf("GAME OVER; HUMAN WINS!!\n");
  } else if(game->computer_score > game->human_score) {
    printf("GAME OVER; COMPUTER WINS!!\n");
  } else {
    printf("GAME OVER; IT'S A TIE!!\n");
  }
}

void game_destroy(game_t *game) {
  gameboard_destroy(game->gameboard);
  free(game);
}

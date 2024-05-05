#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

/* This doesn't use the period skipping trick to reduce work */

uint64_t stime = 449713211;
uint64_t state = 0xab911813bb288b88;
uint64_t taps =
    (1UL << (62 - 3)) |
    (1UL << (62 - 15)) |
    (1UL << (62 - 31)) |
    (1UL << (62 - 43)) |
    (1UL << (62 - 47)) |
    (1UL << (62 - 51)) |
    (1UL << (62 - 55));


void next_lfsr() {

    char bit = (state & 0x8000000000000000) >> 63;

    if (bit == 1) {
        state ^= taps;
    }

    state = (state << 1) | bit;
}


void print_state_hex() {

    printf("%016lx\n", state);
}


int main(int argc, char *argv[]) {

    if (argc != 2) {
        fprintf(stderr, "Expected one argument!\n");
        return -1;
    }

    uint64_t ttime = strtoll(argv[1], 0, 10);

    while (stime < ttime) {
        next_lfsr();
        stime++;
    }
    print_state_hex();

    return 0;
}

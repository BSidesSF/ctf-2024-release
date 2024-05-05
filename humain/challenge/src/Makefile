CC=gcc

CFLAGS=-Wall -Wextra -march=native -O2
#CFLAGS=-std=c99 -Wall -Wextra -march=native -O0 -frounding-math
LIBS=-lm

main: humain

humain: challenge.o
	$(CC) $(CFLAGS) -o humain challenge.o $(LIBS)

challenge.o: challenge.c
	$(CC) $(CFLAGS) -c challenge.c

clean:
	rm -f humain
	rm -f *.o
	rm -f *~
	rm -f \#*


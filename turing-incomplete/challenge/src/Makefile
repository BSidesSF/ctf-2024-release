CFLAGS?=-Wall -m32
LIBS=turing-incomplete.o

all: turing-incomplete

turing-incomplete: ${LIBS}
	gcc ${CFLAGS} -o turing-incomplete ${LIBS}

clean:
	rm -f *.o turing-incomplete

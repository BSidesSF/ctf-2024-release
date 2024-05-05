CFLAGS?=-Wall
LIBS=turing-incomplete64.o

all: turing-incomplete64

turing-incomplete64: ${LIBS}
	gcc ${CFLAGS} -o turing-incomplete64 ${LIBS}

clean:
	rm -f *.o turing-incomplete64

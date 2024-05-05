CFLAGS?=-Wall -m32
LIBS=turing-complete.o

all: turing-complete

turing-complete: ${LIBS}
	gcc ${CFLAGS} -o turing-complete ${LIBS}

clean:
	rm -f *.o turing-complete

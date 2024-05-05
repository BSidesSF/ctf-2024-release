CFLAGS?=-Wall -fno-stack-protector -no-pie -g -static
LIBS=slay-the-spider.o gameboard.o game.o ai.o util.o

all: slay-the-spider

slay-the-spider: ${LIBS}
	gcc ${CFLAGS} -o slay-the-spider ${LIBS}

clean:
	rm -f *.o slay-the-spider

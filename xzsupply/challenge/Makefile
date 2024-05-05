OBJS=myenv.o crypto.o io.o xzsupply.o bd.o compress.o
CC=gcc
override CFLAGS+=-I. -g -O1 -Wall -std=gnu99
# this is hacky
LDFLAGS=-ldl
DEPS=xzsupply.h

xzsupply: xzsupply.dbg
	strip -o $@ $<

xzsupply.dbg: $(OBJS) liblzma.a
	gcc -o $@ $^ $(CFLAGS) $(LDFLAGS)

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm -f *.o xzsupply xzsupply.dbg

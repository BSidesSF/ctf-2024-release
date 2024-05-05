CFLAGS?=-Wall -fno-stack-protector -no-pie -static -g

all: auth.cgi

auth.cgi: auth.c
	gcc ${CFLAGS} -o auth.cgi auth.c

clean:
	rm -f *.o auth.cgi

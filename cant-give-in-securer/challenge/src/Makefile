CFLAGS?=-Wall -fno-stack-protector -no-pie -static

all: auth.cgi

auth.cgi: auth.c
	gcc ${CFLAGS} -o auth.cgi auth.c
	strip auth.cgi

clean:
	rm -f *.o auth.cgi

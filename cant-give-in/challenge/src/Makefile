CFLAGS?=-Wall -fno-stack-protector -no-pie -z execstack -z norelro -static -g

all: auth.cgi

auth.cgi: auth.c
	gcc ${CFLAGS} -o auth.cgi auth.c

clean:
	rm -f *.o auth.cgi

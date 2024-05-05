GO=go

main: truthescrow

truthescrow: truthescrow.go
	GOPATH=`pwd` $(GO) build truthescrow.go

clean:
	rm -f truthescrow
	rm -f *.o
	rm -f *~
	rm -f \#*

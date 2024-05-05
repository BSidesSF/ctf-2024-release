
main:
	clang -S -emit-llvm llflagprinter.c
	llvm-as llflagprinter.ll

clean:
	rm -f llflagprinter
	rm -f *.ll
	rm -f *.bc
	rm -f *.o
	rm -f *~
	rm -f \#*


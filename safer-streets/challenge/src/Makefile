all: safer-streets print-flag

safer-streets: safer-streets.c
	@if [ -d "/usr/include/ImageMagick-7" ]; then \
		gcc -DHAVE_IMAGEMAGICK7 -I/usr/include/ImageMagick-7 -DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16 -Wall -Wno-parentheses -g -O2 -c safer-streets.c -o safer-streets.o; \
		gcc -o safer-streets safer-streets.o /usr/lib64/libMagickWand-7.Q16HDRI.so /usr/lib64/libzbar.so -ljpeg -lX11; \
	elif [ -d "/usr/include/ImageMagick-6" ]; then \
		gcc -I/usr/include/ImageMagick-6 -I/usr/include/x86_64-linux-gnu/ImageMagick-6 -DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16 -Wall -Wno-parentheses -g -O2 -c safer-streets.c -o safer-streets.o; \
		gcc -o safer-streets safer-streets.o /usr/lib/x86_64-linux-gnu/libMagickWand-6.Q16.so /usr/lib/x86_64-linux-gnu/libzbar.so -ljpeg -lX11; \
	else \
		echo "ImageMagick 6 nor 7 were found!"; \
	fi \

	@echo "Done?"

clean:
	rm -f *.o safer-streets

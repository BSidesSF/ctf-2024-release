#define _GNU_SOURCE /* gives M_PI */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#define KLEN 33


/* Original flag */
/*uint8_t flag[KLEN] = {
    'C', 'T', 'F',  '{',
    'l', 'l', 'v', 'm',
    '_', 'a', '_', 'l',
    'l', 'm', '_', 'f',
    'o', 'r', '_', 'v',
    '_', 'e', 'n', 't',
    'h', 'u', 's', 'i',
    'a', 's', 't', 's',
    '}'
    };*/


/*double  dct_vals[KLEN];*/ /* dct of flag */
uint8_t decode_vals[KLEN];


double  encode_vals[KLEN] = {
	3465.000000000000000,
	-138.462748601430150,
	-19.856313604584233,
	-79.107955843710499,
	-52.758590531222509,
	-94.273231680413389,
	-74.572454564840243,
	-116.246423727534321,
	-18.474953231911257,
	-68.339105357184337,
	8.111215357691661,
	39.837168574084046,
	2.468814008571417,
	-19.680086280225407,
	-31.141569570106288,
	25.502387335685818,
	20.050811948489976,
	38.073786243150714,
	21.823003097121287,
	-11.777538585152870,
	90.323801308151317,
	-16.275663134739332,
	-27.000000000001659,
	-10.077941613740336,
	-20.852343032037336,
	-69.954399077492738,
	-51.908363557794551,
	-26.649184432440151,
	-40.557406809236390,
	-42.594859122211695,
	-15.134077555749064,
	-0.098578451523126,
	-70.878694059068877,
};

/*void dct() {*/
    /* DCT-II */

/*    for (int k = 0; k < KLEN; k++) {
        double val = 0.0;
        for (int n = 0; n < KLEN; n++) {
            val += (double)flag[n] * cos((M_PI / (double)KLEN) * ((double)n + (1.0 / 2.0)) * (double)k);
        }
        dct_vals[k] = val;
    }

    }*/


void decode() {
    /* DCT-III (inverse DCT-II) */

    for (int k = 0; k < KLEN; k++) {
        double val = (1.0 / ((double)KLEN)) * encode_vals[0];
        for (int n = 1; n < KLEN; n++) {
            val += (2.0 * encode_vals[n] / (double)KLEN) * cos((M_PI / (double)KLEN) * ((double)k + (1.0 / 2.0)) * (double)n);
        }
        decode_vals[k] = (uint8_t)round(val);
    }
}


int main(void) {

    /*dct();*/ /* decompose into cosines for checking */
    decode();

    /*
    for (int i = 0; i < KLEN; i++) {
        fprintf(stderr, "Key byte: %3d; dct val: %.15f; recovered idct key byte: %d; error: %d\n", flag[i], dct_vals[i], idct_vals[i], flag[i] - idct_vals[i]);
    }

    fprintf(stderr, "double  dct_vals[KLEN] = {\n");
    for (int i = 0; i < KLEN; i++) {
        fprintf(stderr, "\t%.15f,\n", dct_vals[i]);
    }
    fprintf(stderr, "};\n");
    */

    for (int i = 0; i < KLEN; i++) {
        putchar((char)decode_vals[i]);
    }
    putchar('\n');

    return 0;
}



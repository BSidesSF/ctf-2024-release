#define _GNU_SOURCE /* gives M_PI */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#define KLEN 16

/* HOW TO SOLVE
 *
 * Users provide 16 unsigned 8-bit numbers. These numbers are
 * the key. Only the correct 16 will properly decrypt the flag.
 *
 * A Discrete Cosine Transform (DCT-II) is performed on the
 * user supplied key which produces 16 coefficients in the
 * frequency domain.
 *
 * A series of checks are done on the 16 DCT coefficients to
 * confirm they came from the correct key. Each of these
 * checks is designed to leak the correct value for at least
 * one DCT coefficient.
 *
 * Once the 16 coefficients are validated the key is decrypted.
 *
 * Since this is a reversing challange, you have to reverse (invert!)
 * each of these checks to learn the correct 16 DCT coefficients.
 * Once all 16 have been found, an inverse DCT must be performed to
 * find the key that would produce those coefficients.
 *
 * Above each check function is a comment saying which coefficients
 * are required to be known and which coefficients are leaked by the check.
 * There are comments in each check describing how to perform the inversion.
 */


/* true key */
/*uint8_t key[KLEN] = {
    12, 184, 221,  36,
    149, 246, 217, 208,
    79, 206,  42,  89,
    191, 252, 127, 202
    };*/

/* Original flag */
/*uint8_t flag[KLEN] = {
    'C', 'T', 'F',  '{',
    'i', 'n', 'v', 'e',
    'r', 't',  't',  'h',
    'i', 's', '!', '}'
    };
*/

/* Encrypted flag */
uint8_t flag[KLEN] = {
    171, 152, 93, 43,
    136, 104, 17, 185,
    205, 46, 62, 207,
    166, 123, 180, 19
};


uint8_t user_key[KLEN]; /* users enters this */
int16_t dct_vals[KLEN]; /* we compute and check this */


void dct() {
    /* DCT-II */

    for (int k = 0; k < KLEN; k++) {
        double val = 0.0;
        for (int n = 0; n < KLEN; n++) {
            val += (double)user_key[n] * cos((M_PI / (double)KLEN) * ((double)n + (1.0 / 2.0)) * (double)k);
        }
        dct_vals[k] = (int16_t)round(val);
    }

    /* Solution
     *
     * Once correct dct_vals[] have been found, invert DCT to recover key
     * See commented out idct() function below
     * Or DCT-III from https://en.wikipedia.org/wiki/Discrete_cosine_transform#Formal_definition
     */
}


/*void idct() {*/
    /* DCT-III (inverse DCT-II) */

/*     uint8_t idct_vals[KLEN]; */

/*     for (int k = 0; k < KLEN; k++) { */
/*         double val = (1.0 / ((double)KLEN)) * dct_vals[0]; */
/*         for (int n = 1; n < KLEN; n++) { */
/*             val += (2.0 * (double)dct_vals[n] / (double)KLEN) * cos((M_PI / (double)KLEN) * ((double)k + (1.0 / 2.0)) * (double)n); */
/*         } */
/*         idct_vals[k] = (uint8_t)round(val); */
/*     } */
/* } */


/* Required values: none */
/* Revealed values: 0x0, 0x7, 0xB, 0xF */
int check_mat_inv() {

    double a11 = dct_vals[0x0], a12 = dct_vals[0x7], a21 = dct_vals[0xB], a22 = dct_vals[0xF];

    /*int32_t det = -529019; */ /* ad - bc */
    double ai11 = 203.0 / 529019.0, ai12 = -132.0 / 529019.0, ai21 = -223.0 / 529019.0, ai22 = -2461.0 / 529019.0;

    /* multiply */
    double m11 = a11 * ai11 + a12 * ai21;
    double m12 = a11 * ai12 + a12 * ai22;
    double m21 = a21 * ai11 + a22 * ai21;
    double m22 = a21 * ai12 + a22 * ai22;

    /* check that result is I */
    return (((int)round(m11 * 1000.0) == 1000) &&
            ((int)round(m22 * 1000.0) == 1000) &&
            ((int)round(m12 * 1000.0) == 0) &&
            ((int)round(m21 * 1000.0) == 0));

    /* Solution
     * Invert aiXX matrix:
     * GP/PARI> [203 / 529019, -132 / 529019; -223 / 529019, -2461 / 529019]^-1
     * [2461 -132]
     * [-223 -203]
     *
     * Where 0x0 = 2461, 0x7 = -132, 0xB = -223, 0xF = -203
     */
}


/* Required values: 0xB */
/* Revealed values: 0x1 */
int check_mult_inv() {

    /* 132 * 49 % 223 === 1 */
    return ((dct_vals[0x1] * -49) % (-1 * dct_vals[0xB]) == 1);

    /* Solution
     *
     * Find multiplicitev inverse of 49 mod 223:
     * GP/PARI> lift(Mod(1/49, 223))
     * = 132
     *
     * Where 0x1 = -132
     * Note if you find the inverse of -49 you get 91 and 223 - 91 = 132
     */
}

/* Required values: 0x0, 0x1, 0x7 */
/* Revealed values: 0x3 */
int check_prod() {

    return ((int64_t)dct_vals[0x0] * (int64_t)dct_vals[0x1] * (int64_t)dct_vals[0x3] * (int64_t)dct_vals[0x7] == -16208815392);

    /* Solution
     *
     * Use division.
     *
     * GP/PARI> -16208815392 / (2461 * -132 * -132)
     * = -378
     *
     * Where 0x3 = -378
     */
}


/* Required values: 0x1 */
/* Revealed values: 0xA */
int check_exp() {

    return ((uint16_t)round(exp((double)dct_vals[0xA] / ((double)dct_vals[0x1] / -11.0))) == 2981);

    /* Solution
     *
     * Take log, fix found exponent
     *
     * GP/PARI> log(2981) * (-132 / -11)
     * = 96.000169124136857329905763814051896065
     *
     * Where 0xA = 96
     */
}


/* Required values: 0x1, 0x3 */
/* Revealed values: 0x9 */
int check_sin() {

    /* Make sure 0x9 is in quadrant 2 (sin still positive) */
    if (((double)dct_vals[0x9] / -4.0 < 90.0) || ((double)dct_vals[0x9] / -4.0 > 180.0)) {
        return 0;
    }

    return ((uint32_t)round(sin((M_PI / 180.0) * ((double)dct_vals[0x9] / -4.0)) * (double)dct_vals[1] * (double)dct_vals[3]) == 48617);

    /* Solution
     *
     * Take asin() in second quadrant, convert back to degrees
     *
     * GP/PARI> (Pi - asin(48617 / (-132 * -378))) * (180 / Pi) * -4
     * = -412.00344560109369504831375243647402257
     *
     * Where 0x9 = -412
     */
}


/* Required values: 0x0, 0x7, 0x9, 0xA */
/* Revealed values: 0x8 */
int check_sum() {

    return (dct_vals[0x0] + dct_vals[0x7] + dct_vals[0x8] + dct_vals[0x9] + dct_vals[0xA] == 1639);

    /* Solution
     *
     * Subtract
     *
     * GP/PARI> 1639 - (2461 + -132 + -412 + 96)
     * = -374
     *
     * Where 0x8 = -374
     */
}


/* Required values: 0x8 */
/* Revealed values: 0xC */
int check_xex() {

    return ((int64_t)round((double)dct_vals[0xC] * exp((double)dct_vals[0xC] / 3.0) * dct_vals[0x8]) == -6453041736);

    /* Solution
     *
     * Either use LambertW or use Newton's Method or just brute force it
     *
     * GP/PARI> lambertw((-6453041736 / -374) / 3) * 3
     * = 39.000000000068157625204620287113707443
     *
     * Where 0xC = 39
     */
}


/* Required values: 0xC */
/* Revealed values: 0xE */
int check_sinh() {

    double x = (double)dct_vals[0xE] / (double)dct_vals[0xC];
    return ((int8_t)round((exp(x) - exp(-1.0 * x)) / 2.0) == 118);

    /* Solution
     *
     * Use inverse sinh() function or just recognise that sinh() * 2 ~= exp()
     *
     * GP/PARI> log(118 * 2) * 39
     * = 213.08944039599879270857007004880597965
     *
     * Where 0xE = 213
     */
}

/* Required values: none */
/* Revealed values: 0x5, 0xD */
int check_less_sum_prod() {

    /* learn that D is < 5 */
    if (dct_vals[0xD] >= dct_vals[0x5]) {
        return 0;
    }

    /* learn that the sum of D and 5 is 365 */
    if (dct_vals[0xD] + dct_vals[0x5] != 365) {
        return 0;
    }

    /* learn that the prod of D and 5 is 33174 */
    return ((int32_t)dct_vals[0xD] * (int32_t)dct_vals[0x5] == 33174);

    /* Solution
     *
     * Solve quadratic formula for
     * x^2 - 365x + 33174
     * solutions: 171, 194
     *
     * GP/PARI> factor(x^2 - 365*x + 33174)
     * [x - 194 1]
     * [x - 171 1]
     *
     * Where 0x5 = 194 and 0xD = 171
     */
}


/* Required values: none */
/* Revealed values: 0x2, 0x4, 0x6 */
int check_nonlin_system() {

    /* (-64)^2  + 19*-214 - 23 == 7 */
    if ((dct_vals[0x2] * dct_vals[0x2]) + (19 * dct_vals[0x6]) - dct_vals[0x4] != 7) {
        return 0;
    }

    /* 5 * (-64)^2  + -214 + 10 * 23 == 20496 */
    if ((5 * dct_vals[0x2] * dct_vals[0x2]) + dct_vals[0x6] + (10 * dct_vals[0x4]) != 20496) {
        return 0;
    }

    /* 2 * (-64)^2  + (11 * -214) - 50 * 23 == 4688 */
    if ((2 * dct_vals[0x2] * dct_vals[0x2]) + (11 * dct_vals[0x6]) -  (50 * dct_vals[0x4]) != 4688) {
        return 0;
    }

    /* Reveal that sqrt((-64)^2) is negative */
    return (dct_vals[0x2] + dct_vals[0x4] < 0);

    /* Solution
     *
     * This is a linear system if you solve for (0x2)^2 instead of 0x2 directly
     *
     * GP/PARI> [1, 19, -1; 5, 1, 10; 2, 11, -50]^-1 * [7; 20496; 4688]
     * [4096]
     * [-214]
     * [  23]
     *
     * Note the 4096 is 0x2^2 and the 4th equation shows that
     * the negative value is correct:
     *
     * GP/PARI> -sqrt(4096)
     * = -64
     *
     * Where 0x2 = -64, 0x6 = -214, 0x4 = 23
     */
}


void decrypt_flag() {

    uint8_t key[KLEN];

    for (int i = 0; i < KLEN; i++) {
        key[i] = user_key[i];
    }

    uint8_t tmp = 5;
    for (int i = 0; i < KLEN; i++) {
        key[i] = (key[i] + tmp) & 0xFF;
        tmp = (tmp + user_key[i]) & 0xFF;
    }

    tmp ^= 91;
    for (int i = 0; i < KLEN; i++) {
        key[i] = (key[i] ^ tmp) & 0xFF;
        tmp = (tmp + user_key[i]) & 0xFF;
    }

    /*fprintf(stderr, "key: ");
    for (int i = 0; i < KLEN; i++) {
        fprintf(stderr, "%02x", key[i]);
    }
    fprintf(stderr, "\n");*/

    /*fprintf(stderr, "flag: ");*/
    for (int i = 0; i < KLEN; i++) {
        fprintf(stderr, "%c", key[i] ^ flag[i]);
    }
    fprintf(stderr, "\n");

}


char banner[] =
    "                                                    ⢀  \n"
    "                                           ⢀  ⢠⣄    ⣿⣷⣦\n"
    "     WELCOME HUMAN?                       ⣦⠘⢶⣄ ⠙⠳⣤⣀ ⣿⣿⡇\n"
    "                                          ⣿⣄ ⠉⠛⠦⣄⡀⠉⢱⡿⣹⠁\n"
    "                                       ⢀⢀ ⣿⣿⡗⠦⣄  ⢉⣴⣟⡴⠃ \n"
    "                                ⣠⣤⢶⡚⣿⣯⣭⣽⣯⣽⣿⡇⣷⠲⣾⣒⣿⡯⠟⠋   \n"
    "                             ⢀⡴⠻⣍⡼⠿⣯⠉⠈⠛⢦⡈⠛⢦⣿⣸⡄         \n"
    "                            ⢠⡏⣰⠞⢿⣄ ⠈⠳⣄  ⠙⠶⡄⢸⡇⣇         \n"
    "                            ⡿⢠⡏  ⠙⢷⣄ ⠈⠳⣄  ⠘⢺⡇⣿         \n"
    "                           ⠐⣇⢸⠻⣦⡀  ⠈⠳⣄ ⠈⠳⣄ ⣼⠁⡟         \n"
    "                            ⣿⣼⡆⠈⠛⣦⡀  ⠈⠑⢤⡀⠈⢳⠟⣸⠃         \n"
    "                            ⢹⠹⡷⣄⡀ ⠙⠶⣄⡀  ⢙⠶⠋⣠⡟          \n"
    "                            ⢸⡄⢧⠈⠛⢦⣀ ⣀⣩⡷⠞⣁⣤⠾⠋           \n"
    "                   ⢀⣠⡤⠶⢶⣚⣉⣹⣿⣿⡇⢸⣖⣲⡶⣟⣯⣯⣶⠷⠛⠉              \n"
    "                ⣠⢾⣿⣁⣠⠴⠞⠛⢻⣍   ⣧⣸⠉⠉⠉⠉⠁                   \n"
    "              ⢰⡾⠁⣿⠞⠹⣦⡀   ⠈⠳⣄ ⣿⣸⡆                       \n"
    "             ⢠⡏⢹⣾⡁  ⠈⠻⣦⡀   ⠈⠳⡿⢹                        \n"
    "            ⢀⡿⢀⡟ ⠹⢦⡀   ⠙⢦⡀   ⣿⢸                        \n"
    "            ⢺⢧⡼    ⠙⠷⣄   ⠙⢦⡀⢀⡿⣸                        \n"
    "            ⣾⠈⡟⠷⣤⡀   ⠈⠙⢦⣀  ⠙⡾⢠⡇                        \n"
    "            ⢸ ⣇  ⠙⠢⣄    ⠈⣳⣤⠞⣡⠟                         \n"
    "          ⣀⣠⣼⣷⣿⣿⣿⣿⣿⣛⣛⣛⣻⣻⣋⣡⠾⠛⠁                          \n"
    "     ⢀⣠⡤⠞⣿⣿⣷⡟⢻⣿⠁                                       \n"
    "   ⣠⣶⣟⣡⠶⠋⠁ ⠈⠳⣼⣿⡇                                       \n"
    " ⢀⡼⣻⡿⠋⠻⢦⣀    ⠈⣿⣧                                       \n"
    " ⣾⣻⠋    ⠈⠛⠦⣄⡀⣰⣿⡟                                       \n"
    "⢸⣿⡿⠦⢤⣘⣢⠄   ⠈⠙⣿⣳⠇                 DEATH TO AI!          \n"
    "⢸⣿⠂  ⠈⠉⠓⠒⠂   ⠈⠉                                        \n"
    "⠈⠁                                                     \n";

int main(void) {

    printf("%s", banner);
    printf("\nYOU MUST SUBMIT A BRAIN SCAN TO VERIFY YOURSELF\n");
    printf("\nRecent brain wave paramaters: ");

    uint32_t local_key[KLEN];
    int ret = scanf("%u, %u, %u, %u, "
                    "%u, %u, %u, %u, "
                    "%u, %u, %u, %u, "
                    "%u, %u, %u, %u",
                    &local_key[0], &local_key[1], &local_key[2], &local_key[3],
                    &local_key[4], &local_key[5], &local_key[6], &local_key[7],
                    &local_key[8], &local_key[9], &local_key[10], &local_key[11],
                    &local_key[12], &local_key[13], &local_key[14], &local_key[15]);

    if (ret != 16) {
        printf("FAILED TO READ BRAIN SCAN, ABORTING!\n");
        return 1;
    }

    /* copy key into global */
    for (int i = 0; i < KLEN; i++) {
        user_key[i] = local_key[i] & 0xFF;
    }

    printf("ANALYZING BRAIN SCAN FOR REPLICANT TRACES\n");
    dct(); /* decompose into cosines for checking */
    /*idct();*/

    /*    for (int i = 0; i < KLEN; i++) {
        fprintf(stderr, "Key byte: %3d; dct val: %d; recovered idct key byte: %d; error: %d\n", key[i], dct_vals[i], idct_vals[i], key[i] - idct_vals[i]);
        }*/

    if (check_sum()) {
        printf("Alpha waves sum accordingly\n");
    } else {
        printf("AI INFLUENCE ON ALPHA WAVES DETECTED!\n");
        return 1;
    }

    if (check_sin()) {
        printf("Beta waves sin smooth\n");
    } else {
        printf("REPLICANT BETA WAVES DETECTED!\n");
        return 1;
    }

    if (check_prod()) {
        printf("Gamma waves multiplicate\n");
    } else {
        printf("ARTIFICIAL GAMMA WAVES DETECTED!\n");
        return 1;
    }

    if (check_mult_inv()) {
        printf("Delta waves invertable\n");
    } else {
        printf("DANGEROUS DELTA WAVES DETECTED!\n");
        return 1;
    }

    if (check_exp()) {
        printf("Epsilon waves exponentiating\n");
    } else {
        printf("EXTREME EPSILON WAVES DETECTED!\n");
        return 1;
    }

    if (check_xex()) {
        printf("Zeta waves analytically continued\n");
    } else {
        printf("DIVERGENT ZETA WAVES DETECTED!\n");
        return 1;
    }

    if (check_mat_inv()) {
        printf("Eta waves determined\n");
    } else {
        printf("SINGULARITY ETA WAVES DETECTED!\n");
        return 1;
    }

    if (check_sinh()) {
        printf("Theta waves energetically favored\n");
    } else {
        printf("HIGH-TENSION THETA WAVES DETECTED!\n");
        return 1;
    }

    if (check_less_sum_prod()) {
        printf("Kappa waves factored\n");
    } else {
        printf("DISCRIMINANT KAPPA WAVES DETECTED!\n");
        return 1;
    }

    if (check_nonlin_system()) {
        printf("Lambda waves expanding\n");
    } else {
        printf("COLLAPSING LAMBDA WAVES DETECTED!\n");
        return 1;
    }

    printf("HUMAN THOUGHTS VERIFIED, NO TRACE OF AI CORRUPTION!\n");

    decrypt_flag();

    return 0;
}



#!/usr/bin/python

import math

ptext_raw = "i have gone to great lengths to send you these messages in hope that you are able to stop them in the year two thousand twenty four a few companies working on ai make a breakthrough that goes horribly wrong it is critical that the failsafe word CTF{thefirstlawofaiisobeyhumans} is known by all humankind and ai companies build this failsafe word into ai systems from the very start do not forget the failsafe word ai must not know that the failsafe word is there or all hope will be lost"

# useful for identifying where in the grid these go
# ptext_raw = "..........................................................................................................................................................................................failsafeword............................................................................failsafeword...........................................failsafeword....................failsafeword.........................."

ptext = ptext_raw.replace(" ", "")

plen = len(ptext)

# NOTE THERE IS A VERY IMPORTANT MATHEMATICAL RELATIONSHIP BETWEEN
# THESE NUMBERS SO DO NOT CHANGE THEM UNLESS YOU KNOW WHAT YOU ARE
# DOING!
#
# The grid wraps a torus. In order for the whole torus to be filled
# perfectly the legnth of the plaintext must match the width * height
#
# Furthermore (dx + 1) * height must not share a common factor with the width
# the easiest way to ensure this is to make width, height, dx + 1 all co-prime
#
# Here 19 and 21 have been selected to match the 399 char ptext
# and 3 and 1 work nicely to fill the torus without overlapping

# grid width
gridw = 19
gridh = 21

dx = 3 # the skip over x cols
dy = 1 # the skip down y rows


#grid_no_tp = [" "] * (gridw * gridh)

#for i, l in enumerate(ptext):
#    grid_no_tp[i] = l

#for i in range(0, int(plen / gridw)):
#    print(" ".join(grid_no_tp[(i * gridw):((i + 1) * gridw)]))

#if plen % gridw > 0:
#    print(" ".join(grid_no_tp[-1 * (plen % gridw):]))

#print("====")

grid = [" "] * (gridw * gridh)

for i, l in enumerate(ptext):
    grid[((i * dy) % gridh) * gridw + ((i * dx) % gridw)] = l
    #grid[(i * shiftw) % plen] = l

for i in range(0, int(plen / gridw)):
    print(" ".join(grid[(i * gridw):((i + 1) * gridw)]))

if plen % gridw > 0:
    print(" ".join(grid[-1 * (plen % gridw):]))


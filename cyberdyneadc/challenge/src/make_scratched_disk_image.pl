#!/usr/bin/perl

use strict;
use warnings;

my $SECT_BYTES = 256;
my $C = 256; # cyldinders
my $H = 2;   # heads
my $S = 512; # sectors

open (my $DIN, $ARGV[0]) or die 'Unable to open file: ', $!, "\n";



my $scratches;
open (my $SIN, $ARGV[1]) or die 'Unable to open file: ', $!, "\n";
{
    local $/ = undef;
    $scratches  = <$SIN>;
}
close($SIN);

open (my $ERROUT, '>', $ARGV[2]) or die 'Unable to open file: ', $!, "\n";

print $ERROUT '# lba,c,h,s', "\n";

#die 'Disk is wrong size for geometry!', "\n" unless (length($disk) == $SECT_BYTES * $C * $H * $S);

# one side of disk worth of scratches
die 'Scratches is wrong size for geometry!', "\n" unless(length($scratches) == $S * $C);

my @scratch_sect = unpack('C*', $scratches);

my $zero_sect = "\0" x $SECT_BYTES;

for (my $ci = 0; $ci < $C; $ci++) {
    for (my $si = 0; $si < $S; $si++) {
        for (my $hi = 0; $hi < $H; $hi++) {

            my $o = $ci * ($S * $H * $SECT_BYTES) + $si * ($H * $SECT_BYTES) + $hi * $SECT_BYTES;



            if (($hi == 0) && ($scratch_sect[$si + $ci * $S] != 0)) {
                print $zero_sect;
                print $ERROUT sprintf('%d,%d,%d,%d', $o / $SECT_BYTES, $ci, $hi, $si), "\n";
            } else {
                #print $sec_data;
                seek($DIN, $o, 0);

                my $sec_data;
                read($DIN, $sec_data, $SECT_BYTES);

                print $sec_data;
            }
        }
    }
}


close($ERROUT);
close($DIN);

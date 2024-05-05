#!/usr/bin/perl

use strict;
use warnings;

die 'Must provide file as first argument!', "\n" unless ((exists $ARGV[0]) && (-f $ARGV[0]));

my $H = 3072; # image height

my $sgi_data;
open(my $INsgi, '<', $ARGV[0]) or die 'Unable to open file: ', $ARGV[0], ' ', $!, "\n";
{
    local $/ = undef;
    $sgi_data  = <$INsgi>;
}
close($INsgi);

# Flag 1 hidden raw in file name header
my $f1_data = substr($sgi_data, 0x18, 80);
$f1_data =~ s/[^\s!-~]//g;
print 'Flag 1: ', $f1_data, "\n";

# Flag 2 hidden XOR with FF in header padding
my $f2_data = substr($sgi_data, 0x6c, 404);
$f2_data ^= ("\xff" x 404);
$f2_data =~ s/[^\s!-~]//g;
print 'Flag 2: ', $f2_data, "\n";

# Flag 3 hidden with alpha channel. print for placeholder
print 'Flag 3: <hidden by alpha channel, check image editor for flag>', "\n";

# Flag 4 is hidden between scanlines
# Data can be found by looking for the size of each scanline
# in the length table and looking for gaps where the offset to
# the next scanline is bigger

my $sc_offsets = substr($sgi_data, 512, 3072 * 4 * 4);
my $sc_lens = substr($sgi_data, 512 + 3072 * 4 * 4, 3072 * 4 * 4);

my @offs = unpack('N*', $sc_offsets);
my @lens = unpack('N*', $sc_lens);

my $hidden_data = '';
for (my $i = 0; $i < (3072 * 4) - 1; $i++) {
    my $gap = $offs[$i + 1] - $offs[$i];

    my $extra = $gap - $lens[$i];
    if ($extra > 0) {
        #warn sprintf('Found %d extra bytes between scanline %d and %d', $extra, $i, $i + 1), "\n";
        $hidden_data .= substr($sgi_data, $offs[$i] + $lens[$i], $extra);
    }
}
print 'Flag 4: ', $hidden_data, "\n";

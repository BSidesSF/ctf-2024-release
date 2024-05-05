#!/usr/bin/perl

use strict;
use warnings;

my $IDIR = './symbols';

my $GW = 19;
my $GH = 21;

my $ROT_MAX = 10;

my $BOX_L = 350;  # Pixels of width for each character box
my $CHAR_L = 200; # Size of each character
my $PAD_L = int(($BOX_L - $CHAR_L) / 2);

my $IMG_W = $GW * $BOX_L;
my $IMG_H = $GH * $BOX_L;


my $GRIDSTR = `./buildgrid.py`;
$GRIDSTR =~ s/\s+//g;

my @gridl = split(//, $GRIDSTR);

die 'Grid wrong length!', "\n" unless (scalar @gridl == $GW * $GH);



my $cmd = sprintf('convert -set colorspace Gray -size %dx%d xc:white', $IMG_W, $IMG_H);

for (my $y = 0; $y < $GH; $y++) {
    for (my $x = 0; $x < $GW; $x++) {

        my $gidx = ($y * $GW) + $x;

        my $let = $gridl[$gidx];

        if ($let eq '{') {
            $let = 'left';
        } elsif ($let eq '}') {
            $let = 'right';
        } elsif ($let =~ m/^[a-zA-Z]/) {
            $let = lc($let);
        } else {
            die 'Uknown letter ', $let, "\n";
        }

        my $lname = sprintf('%s/%s.png', $IDIR, $let);

        my $ox = ($x * $BOX_L) + $PAD_L;
        my $oy = ($y * $BOX_L) + $PAD_L;

        my $rot = $ROT_MAX - rand(($ROT_MAX * 2) + 1);

        my $rcmd = sprintf(' \\( %s -resize %dx%d\\! -background white -rotate %d -crop %dx%d -repage +%d+%d -compose Multiply \\)', $lname, $CHAR_L, $CHAR_L, $rot, $CHAR_L, $CHAR_L, $ox, $oy);

        $cmd .= $rcmd;
    }
}

$cmd = $cmd . sprintf(' -layers flatten -alpha off png:/tmp/test.png');

my $ret = `$cmd`;

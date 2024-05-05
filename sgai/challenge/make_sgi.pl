#!/usr/bin/perl

use strict;
use warnings;

my $out_fname = 'out.sgi';

my $rgb_fname = 'term_raw_rgb.raw';   # rgb channels from this file
my $rgba_fname = 'term_raw_rgba.raw'; # alpha channel from this file

my $RLE = 1;

my $W = 3072;
my $H = 3072;

my $FLAG1 = 'CTF{i_name_thee_flag}'; # In file name header
my $FLAG2 = 'CTF{padpadpad_really_do_we_need_512}'; # In header padding
my $FLAG3 = 'CTF{invisibility_cloak}'; # This is already in the pixel data, gets hidden by alpha channel
my $FLAG4 = 'CTF{hey_is_there_a_gap_in_these_scanlines}'; # In bytes between scan lines

warn 'Reading RGB data', "\n";
my $rgb_data;
open(my $INrgb, '<', $rgb_fname) or die 'Unable to open file: ', $rgb_fname, ' ', $!, "\n";
{
    local $/ = undef;
    $rgb_data  = <$INrgb>;
}
close($INrgb);

die sprintf('rgb wrong size, got %d, expected %d, ', length($rgb_data), $W * $H * 3) unless (length($rgb_data) == $W * $H * 3);

warn 'Reading RGBA data', "\n";
my $rgba_data;
open(my $INrgba, '<', $rgba_fname) or die 'Unable to open file: ', $rgba_fname, ' ', $!, "\n";
{
    local $/ = undef;
    $rgba_data  = <$INrgba>;
}
close($INrgba);

die sprintf('rgba wrong size, got %d, expected %d, ', length($rgba_data), $W * $H * 4) unless (length($rgba_data) == $W * $H * 4);

warn 'Splitting interlaced channels', "\n";
# split interlaced channels into distinct parts
my $chan_r = '';
my $chan_g = '';
my $chan_b = '';
my $chan_a = '';
for (my $y = 0; $y < $H; $y++) {
    for (my $x = 0; $x < $W; $x++) {
        $chan_r .= substr($rgb_data, (($x + ($y * $W)) * 3) + 0, 1);
        $chan_g .= substr($rgb_data, (($x + ($y * $W)) * 3) + 1, 1);
        $chan_b .= substr($rgb_data, (($x + ($y * $W)) * 3) + 2, 1);
        $chan_a .= substr($rgba_data, (($x + ($y * $W)) * 4) + 3, 1);
    }
}

# DEBUG blank out alpha
#$chan_a = pack('C', 255) x ($H * $W);


warn 'Turning channels into scanlines', "\n";
# Channel scanlines
my @sc_r = ();
my @sc_g = ();
my @sc_b = ();
my @sc_a = ();

warn 'Turning red channel into scanlines', "\n";
channel_to_scanlines($chan_r, \@sc_r);
warn 'Turning green channel into scanlines', "\n";
channel_to_scanlines($chan_g, \@sc_g);
warn 'Turning blue channel into scanlines', "\n";
channel_to_scanlines($chan_b, \@sc_b);
warn 'Turning alpha channel into scanlines', "\n";
channel_to_scanlines($chan_a, \@sc_a);

# The RLE scanline offset / length data
my $out_tot = 512 + ($H * 4 * 4 * 2); # Scanlines * channels * 4 bytes * 2 (offest + len)
my @sc_offset = ();
my @sc_len = ();

my $f4i = 0; # flag 4 index

warn 'Computing offest and length tables', "\n";
# R
for (my $i = 0; $i < $H; $i++) {
    my $l = length($sc_r[$i]);
    push @sc_offset, $out_tot;
    push @sc_len, $l;
    $out_tot += $l;

    # Hide flag 4 between red channel scanlines
    if ($f4i < length($FLAG4)) {
        $sc_r[$i] .= substr($FLAG4, $f4i, 1);
        $out_tot += 1;
        $f4i++;
    }
}

# G
for (my $i = 0; $i < $H; $i++) {
    my $l = length($sc_g[$i]);
    push @sc_offset, $out_tot;
    push @sc_len, $l;
    $out_tot += $l;
}

# B
for (my $i = 0; $i < $H; $i++) {
    my $l = length($sc_b[$i]);
    push @sc_offset, $out_tot;
    push @sc_len, $l;
    $out_tot += $l;
}

# A
for (my $i = 0; $i < $H; $i++) {
    my $l = length($sc_a[$i]);
    push @sc_offset, $out_tot;
    push @sc_len, $l;
    $out_tot += $l;
}


warn 'Writing image', "\n";


open(my $OUT, '>', $out_fname) or die 'Unable to open file for writing: ', $out_fname, ' ', $!, "\n";

warn 'Writing header', "\n";

# https://paulbourke.net/dataformats/sgirgb/sgiversion.html
# The header consists of the following:

#     Size  | Type   | Name      | Description
# -------------------------------------------------------------------
#   2 bytes | short  | MAGIC     | IRIS image file magic number
#   1 byte  | char   | STORAGE   | Storage format
#   1 byte  | char   | BPC       | Number of bytes per pixel channel
#   2 bytes | ushort | DIMENSION | Number of dimensions
#   2 bytes | ushort | XSIZE     | X size in pixels
#   2 bytes | ushort | YSIZE     | Y size in pixels
#   2 bytes | ushort | ZSIZE     | Number of channels
#   4 bytes | long   | PIXMIN    | Minimum pixel value
#   4 bytes | long   | PIXMAX    | Maximum pixel value
#   4 bytes | char   | DUMMY     | Ignored
#  80 bytes | char   | IMAGENAME | Image name
#   4 bytes | long   | COLORMAP  | Colormap ID
# 404 bytes | char   | DUMMY     | Ignored

# MAGIC, STORAGE, BPC, DIMENSION, XSIZE, YSIZE, ZSIZE, PIMIN, PIXMAX, DUMMY
print $OUT pack('nCCnnnnNNN', 474, (($RLE == 0)? 0 : 1), 1, 3, $W, $H, 4, 0, 255, 0);

# IMAGENAME
print $OUT $FLAG1;
print $OUT ("\0" x (80 - length($FLAG1)));

# COLORMAP
print $OUT pack('N', 0);

# DUMMY (padding)
print $OUT ($FLAG2 ^ ("\xFF" x length($FLAG2)));
print $OUT ("\xFF" x (404 - length($FLAG2)));

if ($RLE == 1) {
    warn 'Writing offest and len tables', "\n";
    print $OUT pack('N*', @sc_offset);
    print $OUT pack('N*', @sc_len);
}


warn 'Writing scanlines', "\n";
#warn 'DEBUG: first red scanline: ', join(' ', unpack('C*', $sc_r[0])), "\n";
#warn 'DEBUG: first green scanline: ', join(' ', unpack('C*', $sc_g[0])), "\n";
#warn 'DEBUG: first blue scanline: ', join(' ', unpack('C*', $sc_b[0])), "\n";
#warn 'DEBUG: first alpha scanline: ', join(' ', unpack('C*', $sc_a[0])), "\n";
warn 'Red channel scanlines', "\n";
for (my $i = 0; $i < $H; $i++) {
    print $OUT $sc_r[$i];
}

warn 'Green channel scanlines', "\n";
for (my $i = 0; $i < $H; $i++) {
    print $OUT $sc_g[$i];
}

warn 'Blue channel scanlines', "\n";
for (my $i = 0; $i < $H; $i++) {
    print $OUT $sc_b[$i];
}

warn 'Alpha channel scanlines', "\n";
for (my $i = 0; $i < $H; $i++) {
    print $OUT $sc_a[$i];
}


close($OUT);


sub channel_to_scanlines {
    my $chan = shift;
    my $slref = shift;

    die sprintf('channel wrong size, got %d, expected %d, ', length($chan), $W * $H) unless (length($chan) == $W * $H);

    for (my $y = ($H - 1); $y >= 0; $y--) {
        my $chan_line = substr($chan, $y * $W, $W);

        if ($RLE == 1) {
            $chan_line = rle_sc($chan_line);
        }

        push @{$slref}, $chan_line;
    }
}


sub rle_sc {
    my $sc = shift;

    my @b = unpack('C*', $sc);

    my @rle_b = ();

    my $i = 0;
    my $c = 0;
    while ($i < $W) {
        my $l = runlen(\@b, $i);

        # clamp to max run length of 127
        if ($l > 127) {
            $l = 127;
        }

        push @rle_b, $l;
        push @rle_b, $b[$i];

        $c += $l;

        $i += $l;
    }
    push @rle_b, 0;

    if ($c != $W) {
        warn 'RLE encoded lengths wrong on scanline, got ', $c, ' expected ', $W, "\n";
    }

    return pack('C*', @rle_b);
}


sub runlen {
    my $bref = shift;
    my $o = shift;

    my $sc_len = scalar @{$bref};

    if ($sc_len <= $o) {
        return 0;
    }

    my $l = 1;
    my $b = $bref->[$o];
    for (my $i = $o + 1; $i < $sc_len; $i++) {
        if ($bref->[$i] == $b) {
            $l++;

            if ($l >= 127) {
                last;
            }
        } else {
            last;
        }
    }

    return $l;
}

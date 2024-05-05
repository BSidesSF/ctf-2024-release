#!/usr/bin/perl

use strict;
use warnings;

use IO::Compress::Deflate qw(deflate $DeflateError) ;

my $data;
open (IN, $ARGV[0]) or die 'Unable to open file: ', $!, "\n";
{
    local $/ = undef;
    $data  = <IN>;
}
close IN;


my $data_start = substr($data, 0, length($data) - 12);
my $data_end = substr($data, length($data) - 12, 12);


print $data_start, make_ztxt_chunk('flag', 'CTF{zhis_zis_zhe_zlag}'), $data_end;


sub make_ztxt_chunk {
    my $keyword = shift;
    my $text = shift;

    my $def_text = deflate_str($text);

    my $chunk = $keyword . "\0" . "\0" . $def_text;
    my $chunk_len = length($chunk);

    $chunk = 'zTXt' . $chunk;

    my $crc = mycrc32($chunk);

    my $final = pack('N', $chunk_len) . $chunk . pack('N', $crc);

    return $final;
}


sub deflate_str {
    my $str = shift;

    my $output;
    my $outref = \$output;

    my $inref = \$str;

    deflate $inref => $outref
        or die "deflate failed: $DeflateError\n";

    return $output;
}


# https://billauer.co.il/blog/2011/05/perl-crc32-crc-xs-module/
sub mycrc32 {
    my ($input, $init_value, $polynomial) = @_;

    $init_value = 0 unless (defined $init_value);
    $polynomial = 0xedb88320 unless (defined $polynomial);

    my @lookup_table;

    for (my $i=0; $i<256; $i++) {
        my $x = $i;
        for (my $j=0; $j<8; $j++) {
            if ($x & 1) {
                $x = ($x >> 1) ^ $polynomial;
            } else {
                $x = $x >> 1;
            }
        }
        push @lookup_table, $x;
    }

    my $crc = $init_value ^ 0xffffffff;

    foreach my $x (unpack ('C*', $input)) {
        $crc = (($crc >> 8) & 0xffffff) ^ $lookup_table[ ($crc ^ $x) & 0xff ];
    }

    $crc = $crc ^ 0xffffffff;

    return $crc;
}

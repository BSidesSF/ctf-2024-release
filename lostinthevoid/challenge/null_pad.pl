#!/usr/bin/perl

use strict;
use warnings;

my $data;
open (IN, $ARGV[0]) or die 'Unable to open file: ', $!, "\n";
{
    local $/ = undef;
    $data  = <IN>;
}
close IN;


my @bytes = unpack('C*', $data);
foreach my $b (@bytes) {
    print pack('CC', $b, 0);
}

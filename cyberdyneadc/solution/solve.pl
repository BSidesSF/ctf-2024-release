#!/usr/bin/perl

use strict;
use warnings;


my $img = "\0" x (256 * 512);

open(my $ERRS, '<', 'read_errors.log') or die 'Unable to open read_errors.log', "\n";

while (<$ERRS>) {
    my $line = $_;
    chomp($line);

    if ($line =~ m/^(\d+)\,/) {
        my $lba = $1;

        my $cmd = sprintf('echo "readlba %d" | ./cyberdyne_adc.pl', $lba) . "\n";

        my $ret = `$cmd`;

        #warn $ret, "\n";

        if ($ret =~ m/UNABLE TO READ BLOCK/) {
            substr($img, $lba / 2, 1) = pack('C', 255);
            warn 'got true error at lba ', $lba, "\n";
        }
    }

}

close($ERRS);


print $img;

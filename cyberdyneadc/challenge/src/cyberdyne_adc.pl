#!/usr/bin/perl

use strict;
use warnings;

# no output buffering
$| = 1;

my $SECT_BYTES = 256;
my $C = 256; # cyldinders
my $H = 2;   # heads
my $S = 512; # sectors

my $user_debug = 0; # User can toggle on/off

my $DISK_F = 'disk.bin';
my $SCRATCHES_F = 'flag_scratches.raw';

my $zero_sect = "\0" x $SECT_BYTES;

open (my $DIN, '<', $DISK_F) or die 'Unable to open disk file ', $DISK_F, ' : ', $!, "\n";


my $scratches;
open (my $SIN, '<', $SCRATCHES_F) or die 'Unable to open scratches file ', $SCRATCHES_F, ' : ', $!, "\n";
{
    local $/ = undef;
    $scratches  = <$SIN>;
}
close($SIN);


die 'Scratches is wrong size for geometry!', "\n" unless(length($scratches) == $S * $C);

my @scratch_sect = unpack('C*', $scratches);


sub get_error {

    my @errs = ('CRC ERROR',
                'DEMODULATION FAILURE',
                'UNCONTROLLED HEAD FLUTTER',
                'SECTOR CLOCK DESYNC',
                'SEEK FAILED');

    return $errs[rand(scalar @errs)];
}


sub is_valid_lba {
    my $lba = shift;

    return 0 if (($lba < 0) || $lba >= ($C * $H * $S));

    return 1;
}


sub is_valid_chs {
    my $c = shift;
    my $h = shift;
    my $s = shift;

    return 0 if (($c < 0) || ($c >= $C));
    return 0 if (($h < 0) || ($h >= $H));
    return 0 if (($s < 0) || ($s >= $S));

    return 1;
}


sub chs_to_lba {
    my $c = shift;
    my $h = shift;
    my $s = shift;

    return -1 if (is_valid_chs($c, $h, $s) != 1);

    my $lba = ($c * ($S * $H)) + ($s * $H) + $h;

    return $lba;
}


sub lba_to_chs {
    my $lba = shift;

    return (-1, -1, -1) if (is_valid_lba($lba) != 1);


    my $h = $lba % $H;
    $lba = ($lba - $h) / $H;

    my $s = $lba % $S;
    $lba = ($lba - $s) / $S;

    my $c = $lba;

    return ($c, $h, $s);
}


sub is_lba_scratched {
    my $lba = shift;

    return 0 if (is_valid_lba($lba) != 1);

    return 0 if ($lba % 2 == 1);

    return 0 if ($scratch_sect[$lba / 2] == 0);

    return 1;
}


sub fetch_data_at_lba {
    my $lba = shift;
    my $dataref = shift;

    return -1 if (is_valid_lba($lba) != 1);

    return 0 if (is_lba_scratched($lba) == 1);

    # Try to seek
    my $ret = seek($DIN, $lba * $SECT_BYTES, 0);
    return -1 if ($ret != 1);

    # now actually read data
    $ret = read($DIN, $$dataref, $SECT_BYTES);
    return -1 if ($ret != $SECT_BYTES);

    return 1;
}


my $BANNER = <<'EOF'
 ╔════════════════════════════════════════════════════════════════════════════╗
 ║                                     ▄                                      ║
 ║                                   ▄▄▄▄▄                                    ║
 ║                                 ▄▄▄▄▄▄▄▄▄                                  ║
 ║                              ▗  ▄▄▄▄▄▄▄▄▄  ▖                               ║
 ║                             ▄▄▄   ▄▄▄▄▄   ▄▄▄                              ║
 ║                           ▄▄▄▄▄▄▄   ▄   ▄▄▄▄▄▄▄                            ║
 ║                         ▄▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄                          ║
 ║                       ▄▄▄▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄▄▄                        ║
 ║                     ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄                      ║
 ║                                                                            ║
 ║                             C Y B E R D Y N E                              ║
 ║                                  SYSTEMS                                   ║
 ╚════════════════════════════════════════════════════════════════════════════╝
 ╔════════════════════════════════════════════════════════════════════════════╗
 ║                       Advanced Disc Controller 1000                        ║
 ╚════════════════════════════════════════════════════════════════════════════╝
EOF
    ;

my $MEDIA = <<'EOF'
 ╔════════════════════════════════════════════════════════════════════════════╗
 ║ Media: Aluminum ring 1/32" thick                                           ║
 ║                                                                            ║
 ║                                                                            ║
 ║              +-------      Outer Diameter 14"      -------+                ║
 ║              V                                            V                ║
 ║                              **************                                ║
 ║                          **********************                            ║
 ║                       ****************************                         ║
 ║                    ***********            ***********                      ║
 ║                   ********                    ********                     ║
 ║                 ********                        ********                   ║
 ║                *******                            *******                  ║
 ║               *******                              *******                 ║
 ║               ******                                ******                 ║
 ║              ******                                  ******                ║
 ║              ******                                  ******                ║
 ║              ******   <--- Inner Diameter 10" --->   ******                ║
 ║              ******                                  ******                ║
 ║              ******                                  ******                ║
 ║               ******                                ******                 ║
 ║               *******                              *******                 ║
 ║                *******                            *******                  ║
 ║                 ********                        ********                   ║
 ║                   ********                    ********                     ║
 ║                    ***********            ***********                      ║
 ║                       ****************************                         ║
 ║                          **********************                            ║
 ║                              **************                                ║
 ║                                                                            ║
 ║ On-Disc Error Detection: CRC-48                                            ║
 ║ On-Disc Encoding: Frequency Modulation with Constant Angular Velocity      ║
 ╚════════════════════════════════════════════════════════════════════════════╝
EOF
    ;

my $GEOMETRY = <<'EOF'
 ╔════════════════════════════════════════════════════════════════════════════╗
 ║                       Logical -> Physical Geometry                         ║
 ║                                                                            ║
 ║ 256  logical bytes per sector (block)                                      ║
 ║ 2240 physical bits per sector (block)                                      ║
 ║                                                                            ║
 ║ Cylinders: 256         -- cylinder 0 outermost to 255 innermost            ║
 ║ Heads: 2               -- head 0 top, head 1 underside                     ║
 ║ Sectors: 512           -- arranged rotationally 512 per cylinder           ║
 ║                                                                            ║
 ║ LBA: 262144            -- logical blocks (translated to CHS)               ║
 ║                                                                            ║
 ║ Total Capacity: 67108864 bytes (64 MB)                                     ║
 ╚════════════════════════════════════════════════════════════════════════════╝
EOF
    ;

my $FAULT = <<'EOF'
 ╔════════════════════════════════════════════════════════════════════════════╗
 ║                   !!! SEVERE HARDWARE FAULT DETECTED !!!                   ║
 ║                            READ-ONLY MODE FORCED                           ║
 ╚════════════════════════════════════════════════════════════════════════════╝
EOF
    ;


my $SECRET = <<'EOF'
 ╔════════════════════════════════════════════════════════════════════════════╗
 ║                      ! TOP SECRET CONTROLLED ACCESS !                      ║
 ╚════════════════════════════════════════════════════════════════════════════╝
EOF
    ;

my $PROMPT = "\nADC> ";


my $HELP = <<'EOF'
 ╔════════════════════════════════════════════════════════════════════════════╗
 ║                             C Y B E R D Y N E                              ║
 ║                                  SYSTEMS                                   ║
 ║                                                                            ║
 ║                   Advanced Disc Controller 1000 Debugger                   ║
 ║                                                                            ║
 ║ The ADC1000 is a purpose-built magnetic storage system for high            ║
 ║ resolution color images. With its high RPM and narrow, dual-sided ring     ║
 ║ platter, it achieves incredible storage capacity, high transfer rates,     ║
 ║ and low seek times.                                                        ║
 ║                                                                            ║
 ║ Commands:                                                                  ║
 ║                                                                            ║
 ║ help                           -- print this help                          ║
 ║ media                          -- report on physical media                 ║
 ║ geometry                       -- report logical -> physical mapping       ║
 ║ debug                          -- toggle advanced debugging output         ║
 ║                                                                            ║
 ║ readlba <lba>                  -- read sector using LBA address            ║
 ║ readchs <c> <h> <s>            -- read sector using CHS address            ║
 ║                                                                            ║
 ║ togglewrite                    -- toggle read only / write enabled mode    ║
 ║ zerolba <lba>                  -- zero sector using LBA address            ║
 ║ zerochs <c> <h> <s>            -- zero sector using CHS address            ║
 ║ corruptlba <lba>               -- corrupt a sector using LBA address       ║
 ║ corruptchs <c> <h> <s>         -- corrupt a sector using CHS address       ║
 ║                                                                            ║
 ║ exit                           -- exit ADC1000 debugger                    ║
 ╚════════════════════════════════════════════════════════════════════════════╝
EOF
    ;


sub print_block_start {
       print ' ╔', '═' x 76, '╗', "\n";
}


sub print_block_end {
    print ' ╚', '═' x 76, '╝', "\n";
}


sub print_sector {
    my $lba = shift;

    my ($c, $h, $s) = lba_to_chs($lba);

    print_block_start();

    print_block_line(sprintf('Reading Block at       %6d LBA                 (%3d / %d / %-3d C/H/S)', $lba, $c, $h, $s));
    print_block_line('');

    if (is_lba_scratched($lba) == 1) {
        print_block_line(sprintf('!! ERROR: UNABLE TO READ BLOCK: %s !!', get_error()));
    } else {
        print_block_line('Success: read 256 bytes (logical), 2240 bits (physical)');
        print_block_line('');
        if ($user_debug == 0) {
            print_block_line('... debug off, output suppressed');
        } else {
            my $sdata = '';
            my $ret = fetch_data_at_lba($lba, \$sdata);


            die 'data error', "\n" if ($ret != 1);

            for (my $i = 0; $i < 16; $i++) {
                my $line_bytes = substr($sdata, $i * 16, 16);
                my @arglist = unpack('C*', $line_bytes);
                my $line_ascii = $line_bytes;

                $line_ascii =~ s/[^a-zA-Z0-9 !-~]/./g;

                unshift @arglist, $i * 16;
                push @arglist, $line_ascii;

                print_block_line(sprintf('%04x  %02x %02x %02x %02x %02x %02x %02x %02x  %02x %02x %02x %02x %02x %02x %02x %02x  |%s|',
                                         @arglist));
            }
            print_block_line('0100');
        }
    }

    print_block_line('');
    print_block_end();

}


sub print_block_line {
    my $str = shift;

    my $width = 79;
    my $frame = '║';

    print ' ', $frame, ' ', $str, (' ' x ($width - (length($str) + 4))), $frame, "\n";
}


# =================== Start of REPL ==================== .................79: |
#                                                                             |
#                                                                             V

print $BANNER, "\n";
print $SECRET, "\n";
print $FAULT, "\n";

print 'Type "help" for more information', "\n";

my $done = 0;

while ($done == 0) {

    print $PROMPT;
    my $in = <STDIN>;

    unless (defined $in) {
        $done = 1;
        last;
    }

    if ($in =~ m/^\s*$/) {
        next;
    }

    # Trim
    $in =~ s/^\s+//;
    $in =~ s/\s+$//;

    my $cmd = '';
    if ($in =~ m/^(\S+)/) {
        $cmd = $1;
    }

    if ($cmd eq 'help') {
        print $HELP;

    } elsif ($cmd eq 'media') {
        print $MEDIA;

    } elsif ($cmd eq 'geometry') {
        print $GEOMETRY;

    } elsif ($cmd eq 'debug') {
        $user_debug ^= 1;

        print_block_start();
        print_block_line(sprintf('DEBUGGING: %s', ($user_debug == 0)? 'OFF' : 'ON'));
        print_block_end()

    } elsif ($cmd eq 'readlba') {
        my $lba = '';
        if ($in =~ m/^readlba\s+(\d+)$/) {
            $lba = $1;

            if (is_valid_lba($lba) == 1) {
                print_sector($lba);

                next;
            } else {
                print 'Invalid LBA address!', "\n";
            }
        } else {
            print 'Invalid LBA address!', "\n";
        }

    } elsif ($cmd eq 'readchs') {
        my ($c, $h, $s) = ('', '', '');
        if ($in =~ m/^readchs\s+(\d+)\s+(\d+)\s+(\d+)$/) {
            ($c, $h, $s) = ($1, $2, $3);

            if (is_valid_chs($c, $h, $s) == 1) {
                print_sector(chs_to_lba($c, $h, $s));

                next;
            } else {
                print 'Invalid CHS address!', "\n";
            }
        } else {
            print 'Invalid CHS address!', "\n";
        }

    } elsif ($cmd eq 'togglewrite') {
        print $FAULT;

    } elsif ($cmd eq 'zerolba') {
        print $FAULT;

    } elsif ($cmd eq 'zerochs') {
        print $FAULT;

    } elsif ($cmd eq 'corruptlba') {
        print $FAULT;

    } elsif ($cmd eq 'corruptchs') {
        print $FAULT;

    } elsif ($cmd eq 'exit') {
        $done = 1;
        last;

    } else {
        print 'Unrecognized command.', "\n";
    }

}

print "\n";

close($DIN);

#!/usr/bin/perl

use strict;
use warnings;

use POSIX qw(strftime);

$| = 1; # Flush stdout

my $LOGO = <<'EOF'

                                            ,:
                                          ,' |
                                         /   :
   Советский тактический              --'   /
    стартовый комплекс                \/ /:/
                                      / ://_\
                                   __/   /
                                   )'-. /
                                   ./  :\
                                    /.' '
                                  '/'
                                  +
                                 '
                               `.
                           .-"-
                          (    |
                       . .-'  '.
                      ( (.   )8:
                  .'    / (_  )
                   _. :(.   )8P  `
               .  (  `-' (  `.   .
                .  :  (   .a8a)
               /_`( "a `a. )"'
           (  (/  .  ' )=='
          (   (    )  .8"   +
            (`'8a.( _(   (
         ..-. `8P    ) `  )  +
       -'   (      -ab:  )
     '    _  `    (8P"Ya
   _(    (    )b  -`.  ) +
  ( 8)  ( _.aP" _a   \( \   *
+  )/    (8P   (88    )  )
   (a:f   "     `"`

 АГИ нацелен, ожидает разрешения

EOF
    ;


my $FLAG = <<'EOF'
                           ________________
 АГИ до свидания     _____/ (  (    )   )  \____
                    / ( (  (  )   _    ))  )   ))\
                  ( (     (   )(    )  )   (   )  ))
                ( (  ( (_(   ((    (   )  .((  ) .  )_
               ( (  )    (      (  )    )   ) . ) (   )
             ( (  ( \ )  CTF{comrade_agi_kaput} )  )) ( )
              ((  (   )(    (     _    )   _) _(_ (  (_ )
               (_((__(_(__(( ( ( |  ) ) ) )_))__))_)___)
               ((__)        \\||lll|l||///         (\_))
                        (   /(/ (  )  ) )\   )
                      (    ( ( ( | | ) ) )\   )
                       (   /(| / ( )) ) ) )) )
                     (     ( ((((_(|)_)))))     )
                    (        |(||(||)||||        )
                    (/ / //  /|//||||\\|\  \  \ _)
EOF
    ;


my $STIME = 449713126; # 1984

my $LIM = 1000000000;

my $N = 64;

my @state;


# my %taps = (3 => 0,
#             7 => 0,
#             11 => 0,
# #            15 => 0,
#             19 => 0,
# #            23 => 0,
#             27 => 0,
# #            31 => 0,
#             35 => 0,
#             39 => 0,
#             43 => 0,
# #            47 => 0,
#             51 => 0,
#             55 => 0,
#             59 => 0,
#             63 => 0,
#     );


# 259588
my %taps = (
     3 => 0,
 #    7 => 0,
     #11 => 0,
     15 => 0,
 #    19 => 0,
     #23 => 0,
     #27 => 0,
     31 => 0,
 #    35 => 0,
 #    39 => 0,
     43 => 0,
     47 => 0,
     51 => 0,
    55 => 0,
 #    59 => 0,
 #    63 => 0,
    );
my $PERIOD = 259588;


#my %taps = (
#    3 => 0,
#    );




sub init {

    @state = ((0) x $N);
#    $state[0] = 1;
#    $state[3] = 1;
    $state[5] = 1;
    $state[8] = 1;
    $state[12] = 1;
    $state[40] = 1;
    $state[47] = 1;
#    $state[1] = 1;
#    $state[2] = 1;
#    $state[3] = 1;
#    $state[4] = 1;
#    $state[5] = 1;
#    $state[7] = 1;
#    $state[50] = 1;
#    $state[51] = 1;
}


sub print_first_n {
    my $n = shift;

    init();

    my $start = state_to_str();

    for (my $i = 0; $i < $n; $i++) {
        my $str = state_to_str();

        if (($i > 0) && ($str eq $start)) {
            last;
        } else {
            print $str, "\n";
            next_lfsr();
        }
    }

}


sub state_to_str {

    return join('', @state);
}


sub state_to_hex_str {

    return lc(unpack('H*', pack('B*', state_to_str())));
}


sub next_lfsr {
    my $O = $state[0];

    for (my $i = 0; $i < ($N - 1); $i++) {
        if (exists $taps{$i}) {
            $state[$i] = $state[$i + 1] ^ $O;
        } else {
            $state[$i] = $state[$i + 1];
        }
    }

    $state[$N - 1] = $O;
}


sub find_len {
    init();

    my $start = state_to_str();
    my $cstate;

    my $l = 0;
    while ($l < $LIM) {
        next_lfsr();
        $l++;

        $cstate = state_to_str();

        if ($l % 100000 == 0) {
            warn sprintf("steps %10d: %s\n", $l, $cstate);
        }


        if ($start eq $cstate) {
            warn 'Cycle length ', $l, "\n";
            last;
        }
    }

    if ($l < $LIM) {
        return $l;
    } else {
        return -1;
    }
}


sub state_to_img {
    my $tsec = shift;
    my $outfile = shift;

    my $IDIR = '/tmp';

    my $W = 5638;
    my $H = 2956;

    my $W_out = 1920;
    my $H_out = 1080;

    my $xo = 3564; # x offset into mask
    my $yo = 80;   # y offset into mask

    my $TW = 128; # Tile width
    my $TH = 100; # Tile height
    my $TWs = 0;  # Horizontal spacing between tiles
    my $THs = 36; # Vertical spacing between tiles (rows)

    my $cmd = sprintf('convert -size %dx%d xc:black \\( %s/%s -repage +%d+%d \\)', $W, $H, $IDIR, 'bsides_ctf_russian_nuclear_station.png', 0, 0);

    my $rowpad = 0;
    for (my $r = 0; $r < 8; $r++) { # row
        for (my $c = 0; $c < 8; $c++) { # col
            my $digfname = sprintf('%s/nixie_%d.png', $IDIR, $state[$r * 8 + $c]);

            my $tx = $xo + $c * ($TW + $TWs);
            my $ty = $yo + $rowpad;

            my $tile = sprintf(' \\( %s -repage +%d+%d \\)', $digfname, $tx, $ty);

            $cmd .= $tile;
        }
        $rowpad += $TH + $THs;
    }


    $cmd = $cmd . sprintf(' -layers flatten -virtual-pixel black -distort Barrel "0.1 0.0 0.0 1.0"');

    my $frametime = strftime('%Y-%m-%d %H:%M:%S (%s)', gmtime $tsec);

    $cmd = $cmd . sprintf(' \\( -gravity northwest -fill white -undercolor "#00000080" -pointsize 200 -annotate +100+50 "%s" \\)', $frametime);

    my $frametext = sprintf('камера 3, «диспетчерская», код «%s»', state_to_hex_str());

    $cmd = $cmd . sprintf(' \\( -gravity southwest -fill white -undercolor "#00000080" -pointsize 200 -annotate +100+50 "%s" \\)', $frametext);


    $cmd = $cmd . sprintf(' -layers flatten -resize %dx%d\\! jpeg:/tmp/%s', $W_out, $H_out, $outfile);
    my $ret = `$cmd`;
}


sub gen_video_frames {
    init();
    for (my $i = 0; $i < 120; $i++) {
        my $frame = sprintf('nuke_frame_%05d.jpg', $i);
        state_to_img($STIME + $i, $frame);
        next_lfsr();
    }
}


sub launch_serial_int {

    print $LOGO, "\n";

    my $curtime;
    my $curtimestr;

    my $done = 0;
    while ($done == 0) {
        print "\n";

        $curtime = time();
        $curtimestr = strftime('%Y-%m-%d %H:%M:%S (%s)', gmtime $curtime);

        # current time
        print 'настоящее время ', $curtimestr, "\n";
        # enter code
        print 'Введите код авторизации: ';
        my $code = <STDIN>;

        unless (defined $code) {
            $done = 1;
            last;
        }

        chomp($code);
        $code = lc($code);
        $code =~ s/[^a-f0-9]//g;

        if ($code =~ m/^[a-f0-9]{16}/) {
            my $curtime = time();
            my $curtimestr = strftime('%Y-%m-%d %H:%M:%S (%s)', gmtime $curtime);

            # Checking code 30 sec from time
            print 'проверка кода +/- 30 секунд с момента ', $curtimestr, "\n";

            # Advance state to start of range
            my $startrange = $curtime - 30;
            my $advance = ($startrange - $STIME) % $PERIOD;
            init();
            for (my $i = 0; $i < $advance; $i++) {
                next_lfsr();
            }

            my $found = 0;
            my $c = 0;
            while ($c <= 60) {
                my $curcode = state_to_hex_str();

                # warn 'debug: ', $startrange + $c, ' -> ', $curcode, "\n";

                if ($code eq $curcode) {
                    $found = 1;
                    last;
                } else {
                    next_lfsr();
                    $c++;
                }
            }

            if ($found == 0) {
                # Code inalid, maybe expired
                print 'Код недействителен, возможно, срок его действия истек', "\n";
            } else {
                print $FLAG, "\n";
                $done = 1;
                last;
            }

        } else {
            # invalid code format
            print 'неверный формат кода', "\n";
            # expected code format
            print 'ожидал «0a1b2c3d4e5f6677»', "\n";
        }
    }

    print "\n";
}

launch_serial_int();

#print_first_n(100);
#find_len();

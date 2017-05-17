#!/usr/bin/env perl

use warnings;
use strict;

use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;

my @colors = qw(black red green yellow blue magenta cyan white);
my @on_colors = qw(on_black on_red on_green on_yellow on_blue on_magenta on_cyan on_white);

sub main {
    for my $effect('', qw(bold underline underscore)) {
        for my $on (@on_colors) {
            for my $c (@colors) {
                color "$effect $c $on";
                print "This line is '$effect' - '$c' '$on'.\n";
            }
        }
    }
}

exit ( main() // 0 );
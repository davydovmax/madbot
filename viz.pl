#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Term::ReadKey;
use File::Slurp;
use JSON qw(decode_json encode_json);
use Term::ANSIScreen qw/:color :cursor :screen :keyboard :constants/;
use Time::HiRes qw(time sleep);

sub print_field_walls {
    my ($field_width, $field_height, $is_wall) = @_;
    for my $col (0..$field_width+1) {
        print "##";
    }
    print "\n";

    for my $row (0..$field_height-1) {
        print "##";
        for my $col (0..$field_width-1) {
            if($is_wall->{$row}->{$col}) {
                print '##';
            }
            else {
                print '  ';
            }
        }
        print "##";

        print "\n";
    }

    for my $col (0..$field_width+1) {
        print "##";
    }
    print "\n";
}

sub print_object {
    my ($row_col, $symbol, $color) = @_;
    #savepos;
    color "$color";
    locate($row_col->[0], $row_col->[1]);
    print "$symbol";
    color 'reset';
    #loadpos;
}

sub _field_coordinate_to_screen_coordinate {
    my ($row__or__row_col, $col) = @_;

    my $row;
    my $use_array_ref;
    if (ref $row__or__row_col eq 'ARRAY') {
        $use_array_ref = 1;
        $row = $row__or__row_col->[0];
        $col = $row__or__row_col->[1];
    }
    else {
        $row = $row__or__row_col;
    }

    $row = $row + 2;
    $col = ($col + 1) * 2 + 1;

    return $use_array_ref ? [$row, $col] : ($row, $col);
}

sub print_field_simple {
    my ($field_width, $field_height, $is_wall, $player0, $player1, $weapons, $snippets, $bugs) = @_;
    cls;
    locate(1,1);

    print_field_walls($field_width, $field_height, $is_wall);
    print_object(_field_coordinate_to_screen_coordinate($player0), '11', 'red');
    print_object(_field_coordinate_to_screen_coordinate($player1), '22', 'blue');

    for my $s (@$snippets) {
        print_object(_field_coordinate_to_screen_coordinate($s), '()', 'green');
    }

    for my $w (@$weapons) {
        print_object(_field_coordinate_to_screen_coordinate($w), 'vv', 'weapons');
    }

    for my $b (@$bugs) {
        print_object(_field_coordinate_to_screen_coordinate($b), '[]', 'magenta');
    }

    return $field_height + 2;
}

sub print_status {
    my ($last_row, $current_round) = @_;
    # XXX: print snippets by bot
    locate($last_row, 1);
    printf "Current round: %s\n", $current_round;
    return $last_row;
}

sub print_help {
    my ($last_row) = @_;
    locate($last_row, 1);
    printf "HELP BE HERE\n";
    return $last_row;
}

sub main {
    my ($screen_width, $screen_height, $wpixels, $hpixels) = GetTerminalSize();

    # open file
    my $result_file = "/Users/md/projects/hack-man-engine/resultfile.json";
    my $json_content = read_file($result_file);
    my $result_data = decode_json($json_content);

    # better handle data
    $result_data->{game} = decode_json($result_data->{game});
    $result_data->{details} = decode_json($result_data->{details});
    for my $player ( @{ $result_data->{players} } ) {
        # split log into separate lines
        $player->{log} = [ split(/\n/, $player->{log}) ];
    }

    # decode field size
    # settings field_width 20
    # settings field_height 14
    my $field_width;
    my $field_height;
    my $game_field_raw;
    my %is_wall = ();
    DONE_PARSING_SETTINGS_FROM_LOG:
    for my $player ( @{ $result_data->{players} } ) {
        for my $log_line ( @{ $player->{log} } ) {
            if ($log_line =~ m/^settings field_width /) {
                (undef, undef, $field_width) = split(' ', $log_line);
            }
            elsif ($log_line =~ m/^settings field_height /) {
                (undef, undef, $field_height) = split(' ', $log_line);
            }
            elsif ($log_line =~ m/^update game field /) {
                (undef, undef, undef, $game_field_raw) = split(' ', $log_line);
                my @cells = split ',', $game_field_raw;
                for my $x (0..$field_height-1) {
                    for my $y (0..$field_width-1) {
                        my $cell = shift @cells;
                        for my $c (split '', $cell) {
                            if ($c eq 'x') {
                                $is_wall{ $x }{ $y } = 1;
                            } elsif ($c eq '.') {
                                # do nothing, let is_wall{ $x }{ $y } be undef
                            }
                        }
                    }
                }
            }

            if($field_height && $field_width && $game_field_raw) {
                last DONE_PARSING_SETTINGS_FROM_LOG;
            }
        }
    }

    # parse game field
    my $field = [
        [], # row...
    ];
    for my $row (0..$field_height-1) {
        for my $column (0..$field_width-1) {
            my $current_row = $field->[$row] //= [];
            $current_row->[$column] = '?';
        }
    }

    my $time_elapsed = $result_data->{timeElapsed};
    my $final_score = $result_data->{details}->{score};
    my $winner = $result_data->{details}->{winner};

    # printf STDERR "time_elapsed: %s\n", $time_elapsed;
    # printf STDERR "final_score: %s\n", $final_score;
    # printf STDERR "winner: %s (%s)\n", $winner, $result_data->{game}->{settings}->{players}->{names}->[$winner];
    # printf STDERR "field: %s x %s\n", $field_width, $field_height;
    # printf STDERR "raw field: %s\n", $game_field_raw;

    # print encode_json($result_data);
    
    for my $state ( @{ $result_data->{game}->{states} } ) {
        # printf "%s %s\n", $state->{round}, '';

        # coordinates are (y, x) => (row, col)
        my $player0 = [ $state->{players}->[0]->{y}, $state->{players}->[0]->{x} ];
        my $player1 = [ $state->{players}->[1]->{y}, $state->{players}->[1]->{x} ];
        my @weapons;
        my @snippets;
        my @bugs;

        for my $snip ( @{ $state->{collectibles} } ) {
            push @snippets, [ $snip->{y}, $snip->{x} ];
        }

        for my $w ( @{ $state->{weapons} } ) {
            push @weapons, [ $w->{y}, $w->{x} ];
        }

        for my $b ( @{ $state->{bugs} } ) {
            push @bugs, [ $b->{y}, $b->{x} ];
        }

        my $last_row = print_field_simple(
            $field_width,
            $field_height,
            \%is_wall,
            $player0, # player0
            $player1, # player1
            \@weapons,
            \@snippets,
            \@bugs,
        );

        $last_row = print_status($last_row + 1, $state->{round});
        $last_row = print_help($last_row + 1);

        sleep 0.6;
    }

    # loop game state


    return 0;
}

exit ( main() // 0 );
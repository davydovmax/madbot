#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Term::ReadKey;
use File::Slurp;
use JSON qw(decode_json encode_json);
use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;

# my @colors = qw(black red green yellow blue magenta cyan white);
# my @on_colors = qw(on_black on_red on_green on_yellow on_blue on_magenta on_cyan on_white);

sub print_field_simple {
    my ($field) = @_;
    for my $row (@$field) {
        for my $e (@$row) {
            print $e;
        }

        print "\n";
    }
}

sub main {
    my ($screen_width, $screen_height, $wpixels, $hpixels) = GetTerminalSize();
    # printf STDERR "Terminal: %s %s %s %s\n", $screen_width, $screen_height, $wpixels, $hpixels;

    # cls;

    # for my $effect('', qw(bold underline underscore blink reverse concealed)) {
    #     for my $c (@colors) {
    #         for my $on ('on_black') {
    #             color "$effect $c $on";
    #             print "This line is '$effect' - '$c' '$on'.\n";
    #         }
    #     }
    # }

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

    printf STDERR "time_elapsed: %s\n", $time_elapsed;
    printf STDERR "final_score: %s\n", $final_score;
    printf STDERR "winner: %s (%s)\n", $winner, $result_data->{game}->{settings}->{players}->{names}->[$winner];
    printf STDERR "field: %s x %s\n", $field_width, $field_height;
    printf STDERR "raw field: %s\n", $game_field_raw;
    print_field_simple($field);
    # print encode_json($result_data);

    # print Dumper($result_data);

    # check terminal size

    # if resized - clear, redraw

    # if same - redraw board

    
}

exit ( main() // 0 );
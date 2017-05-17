#!/usr/bin/env perl

use strict;
use warnings;

$| = 1; # flush STDOUT after every print

my $width;
my $height;
my %is_wall;
my $timebank;
my $time_per_move;
my $time_remaining;
my $max_rounds;
my $current_round;
my %me;
my %enemy;
my @snippets;
my @weapons;
my @bugs;

sub process_next_command {
	my @tokens = split ' ', <>;
	my $command = shift @tokens;
	if ($command eq 'settings') {
		my ($type, $value) = @tokens;
		if ($type eq 'timebank') {
			$timebank = $value;
		} elsif ($type eq 'time_per_move') {
			$time_per_move = $value;
		} elsif ($type eq 'player_names') {
			my $player_names = $value;
			# player names aren't very useful
		} elsif ($type eq 'your_bot') {
			$me{name} = $value;
		} elsif ($type eq 'your_botid') {
			$me{id} = $value;
		} elsif ($type eq 'field_width') {
			$width = $value;
		} elsif ($type eq 'field_height') {
			$height = $value;
		} elsif ($type eq 'max_rounds') {
			$max_rounds = $value;
		}
	} elsif ($command eq 'update') {
		my ($player_name, $type, $value) = @tokens;
		chomp($value);
		if ($type eq 'round') {
			$current_round = $value;
		} elsif ($type eq 'field') {
			@snippets = ();
			@weapons = ();
			@bugs = ();
			%is_wall = ();
			my @cells = split ',', $value;
			for my $x (0..$height-1) {
				for my $y (0..$width-1) {
					my $point = {
						x => $x,
						y => $y,
					};
					my $cell = shift @cells;
					for my $c (split '', $cell) {
						if ($c eq 'x') {
							$is_wall{ $x }{ $y } = 1;
						} elsif ($c eq '.') {
							# do nothing, let is_wall{ $x }{ $y } be undef
						} elsif ($c eq 'E') {
							push @bugs, $point;
						} elsif ($c eq 'W') {
							push @weapons, $point;
						} elsif ($c eq 'C') {
							push @snippets, $point;
						} else {
							# played id
							my $id = ord($c) - ord('0');
							if ($id == $me{id}) {
								$me{x} = $x;
								$me{y} = $y;
							} else {
								$enemy{x} = $x;
								$enemy{y} = $y;
							}
						}
					}
				}
			}
		} elsif ($type eq 'snippets') {
			if ($player_name eq $me{name}) {
				$me{snippets} = $value;
			} else {
				$enemy{snippets} = $value;
			}
		} elsif ($type eq 'has_weapon') {
			if ($player_name eq $me{name}) {
				$me{has_weapon} = ($value eq 'true');
			} else {
				$enemy{has_weapon} = ($value eq 'true');
			}
		} elsif ($type eq 'is_paralyzed') {
			if ($player_name eq $me{name}) {
				$me{is_paralyzed} = ($value eq 'true');
			} else {
				$enemy{is_paralyzed} = ($value eq 'true');
			}
		}
	} elsif ($command eq 'action') {
		my $useless_move = shift @tokens;
		$time_remaining = shift @tokens;
		do_move();
	}
};

#-----------------------------------------#
#  Improve the code below to win 'em all  #
#-----------------------------------------#

my @dx = (-1, 0, 1, 0);
my @dy = (0, -1, 0, 1);
my @moves = qw/up left down right/;

sub do_move {
	my @valid_moves;
	for my $dir (0..3) {
		my $nextx = $me{x} + $dx[$dir];
		my $nexty = $me{y} + $dy[$dir];
		if ($nextx >= 0 && $nextx < $height && $nexty >= 0 && $nexty < $width) {
			if (!$is_wall{ $nextx }{ $nexty }) {
				push @valid_moves, $moves[$dir];
			}
		}
	}
	push @valid_moves, 'pass' if @valid_moves == 0;
	my $valid_move = $valid_moves[rand(scalar @valid_moves)];
	print "$valid_move\n";
};

#---------------------------------------------#
#  Here comes the core part, don't remove it  #
#---------------------------------------------#

while (1) {
	process_next_command();
};
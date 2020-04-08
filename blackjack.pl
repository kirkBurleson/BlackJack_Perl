@deck = ('2','3','4','5','6','7','8','9','10','J','Q','K','A','2','3','4','5','6','7','8','9','10','J','Q','K','A','2','3','4','5','6','7','8','9','10','J','Q','K','A','2','3','4','5','6','7','8','9','10','J','Q','K','A');
@shoe = ();
$pos = 0;
$mark = 0;
@1 = ();
@2 = ();
@3 = ();
@4 = ();
$cur = 1;
$hands = 1;
@dealer = ();
@state = @dealer;
$bet = 0.0;
@bets = ();
@split_aces = ();
$money = 50;
$choice = "";
$playing = 1;

sub start {
	&init;
	&shuffle;

	while ($playing && $money >= 1) {
		# bet
		print "\n\$$money | Bet: \$";
		$bet = &get_bet;
		last if $bet eq "quit";
		next if $bet eq "next";

		$bets[$cur] = $bet;

		# first deal
		push(@{$cur}, &next_card);
		push(@dealer, &next_card);
		push(@{$cur}, &next_card);

		print "\n";
		print "Dealer: @dealer\n";
		print "*******************************************\n";

		# loop through hands
		while ($cur <= $hands) {
			# deal next card for split hand
			if (@{$cur} < 2) {
				push(@{$cur}, &next_card);
			}

			# show aces instead of 1's
			my($total) = &get_total(@{$cur});
			if ($total =~ m/L/ && $split_aces[$cur]) {
				$total = 21;
			}

			@state = @{$cur};
			&ones_to_aces(@state);

			print "\n";
			print "Hand($cur): ==> ", join(' ', @state), " | ", $total, "\n";
			print "-------------------------------------------\n";
			print "\n(H)it (S)tand (D)ouble down s(P)lit (Q)uit: ";
			
			$choice = <STDIN>;
			chomp $choice;
			my($badInput) = $choice =~ m/[^shdpqSHDPQ]/;
			redo if ($badInput);

			if ($choice eq 's' or $choice eq 'S') {
				if ($cur == $hands) { last; }

			} elsif ($choice eq 'h' or $choice eq 'H') {
				push(@{$cur}, &next_card);
				my($total) = &get_total(@{$cur});
				if ($total =~ m/BU/) {
					@state = @{$cur};
					&ones_to_aces(@state);
					print "Hand($cur): ==> ", join(' ', @state), " | ", $total, "\n";
				} else {
					next;
				}

			} elsif ($choice eq 'd' or $choice eq 'D') {
				my($total) = &get_total(@{$cur});
				if (@{$cur} != 2 || $total =~ m/[^9,10,11]/) {
					print "Must have 9, 10, or 11 on first 2 cards dealt.\n";
					next;
				}

				if ($bets[$cur] * 2 > $money) {
					print "You don't have the money to cover the bet.\n";
					next;
				}				

				push(@{$cur}, &next_card);
				$bets[$cur] = $bet * 2;
				print join(' ', @{$cur}), " | ", &get_total(@{$cur}), "\n";

			} elsif ($choice eq 'p' or $choice eq 'P') {
				if ($hands == 4) {
					print "Can't split. Max hands is 4.\n";
					next;
				}

				@state = @{$cur};
				&ones_to_aces(@state);
				if (@{$cur} != 2 || @{$cur} == 2 && $state[0] ne $state[1]) {
					print "Can only split the first 2 cards if they match.\n";
					next;
				}

				if ($state[0] eq 'A' && $state[1] eq 'A') {
					print "Can't blackjack on split aces.\n";
					$split_aces[$cur] = 1;
					$split_aces[$cur + 1] = 1;
				}

				$hands++;
				$next = $cur + 1;
				@{$next}[0] = pop(@{$cur});
				$bets[$next] = $bet;
				@{$cur}[0] = 'A';
				@{$next}[0] = 'A';
				next;

			} elsif ($choice eq 'q' or $choice eq 'Q') {
				$playing = 0;
				last;

			} else {
				next;
			}

			$cur++;
		}

		if ($playing == 0) { last; }

		# Dealer's turn
		push(@dealer, &next_card); # get second card
		while (1) {
			my($total) = &get_total(@dealer);
			@state = @dealer;
			&ones_to_aces(@state);

			print "\n";
			print "Dealer: @state | $total\n";

			if (&has_non_digit($total)) {
				last;
			}

			if ($total > 21) {
				print "Dealer Busts!";
				last;
			}

			if ($total < 17) {
				print "Dealer hits";
				push(@dealer, &next_card);
				next;
			}
			
			if ($total == 17 && &has_soft_17(@dealer)) {
				print "Dealer hits soft 17";
				push(@dealer, &next_card);
				next;
			}

			print "Dealer stands on $total\n";
			last;
		}


		# Calculate winnings
		my($winnings) = 0.0;
		my($dTotal) = &get_total(@dealer);
		my($i) = 1;

		while ($i <= $hands) {
			my($pTotal) = &get_total(@{$i});
			my($bet) = $bets[$i];

			# can't blackjack off split aces
			if ($pTotal =~ m/L/ && $split_aces[$i]) {
				$pTotal = 21;
			}

			# blackjack
			if ($pTotal =~ m/L/ && $dTotal =~ m/L/) {
				$winnings += 0;
			}

			elsif ($pTotal =~ m/L/ && $dTotal =~ m/^L/ == 0) {
				$winnings += $bet * 1.5;
			}

			elsif ($dTotal =~ m/L/ && $pTotal =~ m/^L/ == 0) {
				$winnings -= $bet;
			}

			# bust
			elsif ($pTotal =~ m/U/ && $dTotal =~ m/U/) {
				$winnings += 0;
			}

			elsif ($pTotal =~ m/U/ && $dTotal =~ m/^U/ == 0) {
				$winnings -= $bet;
			}

			elsif ($dTotal =~ m/U/ && $pTotal =~ m/^U/ == 0) {
				$winnings += $bet;
			}

			# biggest
			elsif ($pTotal > $dTotal) {
				$winnings += $bet;
			}

			elsif ($dTotal > $pTotal) {
				$winnings -= $bet;
			}

			$i++;
		}

		# print final hand totals
		print "**********************\n";
		$i = 1;
		while ($i <= $hands) {
			my($total) = &get_total(@{$i});
			if ($total =~ m/L/ && $split_aces[$i]) {
				$total = 21;
			}

			@state = @{$i};
			&ones_to_aces(@state);
			print "Hand($i): ==> ", join(' ', @state), " | ", $total, "\n";

			$i++;
		}

		@state = @dealer;
		&ones_to_aces(@state);
		print "Dealer: @state | ", &get_total(@state), "\n";
		print "**********************\n";

		if ($winnings > 0.0) { print "Winner!\n"; }
		elsif ($winnings < 0.0) { print "Loser!\n"; }
		else { print "Push\n"; }

		$money += $winnings;

		# Reset state
		@1 = ();
		@2 = ();
		@3 = ();
		@4 = ();
		$cur = 1;
		$hands = 1;
		@dealer = ();
		$bet = 0.0;
		@bets = ();
		@split_aces = ();
	}

	if ($money < 1) { print "Out of money.\n"; }
	print "\nbye.\n";
}

sub has_soft_17 {
	if (@_ == 2) {
		if (&has_non_digit(@_)) {
			return $_[0] eq 'A' || $_[1] eq 'A' && $_[0] eq '6' || $_[1] eq '6';
		}
	}

	return 0;
}

sub has_ace {
	my($i) = 0;
	while ($i < @_) {
		if ($_[$i] =~ m/A/) {
			return 1;
		}
		$i++;
	}

	return 0;
}

sub get_bet {
	$bet = <STDIN>;
	chomp $bet;
	if ($bet eq "-1") {
		return "quit";
	}

	my($input) = $bet =~ m/[^0-9]/; # contains non-digit

	if ($bet < 1 or $input) {
		return "next";
	}

	if ($bet > $money) {
		print "You don't have enough money to cover that bet.\n";
		return 'next';
	}

	return $bet;
}

sub ace_to_one {
	for ($i = 0; $i < @_; $i++) {
		if (&has_non_digit($_[$i]) && $_[$i] eq 'A') {
			$_[$i] = '1';
			last;
		}
	}

	return @_;
}

sub ones_to_aces {
	my($i) = 0;
	while ($i < @_) {
		if ($_[$i] eq '1') {
			$_[$i] = 'A';
		}

		$i++;
	}
}

sub get_total {
	my($total) = 0;

	for (my($i) = 0; $i < @_; $i++) {
		if (&has_non_digit($_[$i])) {
			$total += 10;
			if ($_[$i] eq 'A') {
				$total += 1;
			}
		}
		else {
			$total += $_[$i];
		}
	}

	if ($total == 21 && @_ == 2) {
		return 'BLACKJACK';		
	}

	if ($total > 21) {
		if (&has_ace(@_) == 0) {
			return 'BUST';
		}

		&ace_to_one(@_);
		$total = &get_total(@_);
	}

	return $total;
}

sub has_non_digit {
	my($tmp) = join('',@_) =~ m/[^0-9]/;
	return $tmp;
}

sub init {
	# create 4 decks of cards
	push(@shoe, @deck);
	push(@shoe, @deck);
	push(@shoe, @deck);
	push(@shoe, @deck);
}

sub shuffle {
	my($pos) = 0;
	my($end) = @shoe + 0;
	$mark = $end - (int(rand(40)) + 10);

	while ($end > 0) {
		$pos = int(rand($end));
		$end--; # -1 for indexing
		($shoe[$pos], $shoe[$end]) = ($shoe[$end], $shoe[$pos]);
	}
}

sub next_card {
	if ($pos == $mark) {
		print "Deck shuffled.";
		&shuffle;
		$pos = 0;
	}

	return $shoe[++$pos];
}

# ------------------------
&start
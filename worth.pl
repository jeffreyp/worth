#!/usr/bin/perl
#
# Ghetto script (is there any other kind?) to
# keep me from quitting.
#

use strict;

use Data::Dumper;
use Date::Calc;
use Getopt::Long qw(GetOptions);
use LWP::UserAgent;

use constant ONE_MILLION_DOLLARS => 1000000;

# Gather command-line options
my %opts;
my ($ticker, $help, $usage, $value);
%opts = GetOptions(
       "ticker=s" => \$ticker,
       "help"     => \$help,
       "usage"    => \$usage,
	   "value=s"  => \$value,
	);

# Validate required options
unless ($ticker) {
	usage_and_exit();
}

# CHANGE ME #1
# How many shares are you holding?
my $vested_shares = 100; 

# CHANGE ME #2
# What is your vesting schedule?
# 'YYYY-MM-DD' => number of shares,
# 'YYYY-MM-DD' => number of shares,
my %vesting_map = (
   '2011-11-15' => 100,
   '2012-05-15' => 100,
	);

# Party time.
exit main();

sub main {
    # Just in case our user is lazy
	$ticker = uc($ticker);

	my $quote = 0.00; 

	# Playtime scenario
	if ($value && $value > 0) {
		$quote = $value;

    # Load the quote information from tha interwebs
	} else {
		my $html = get_raw_html($ticker);
		$quote = parse_html($html);
	}

    # Easy part: vested shares times quote = value of vested shares.
	my $vested_worth = $vested_shares * $quote;
	print "Let's start with the good news:\n\n";
	printf "\tYou currently own %s shares worth %s.\n", $vested_shares, format_usd($vested_worth);

    # First add up the total unvested value.
	my $total_unvested = 0.00;
	my $unvested_shares = 0;
	foreach my $shares (values %vesting_map) {
		$total_unvested = $total_unvested + ($shares * $quote);
		$unvested_shares = $unvested_shares + $shares;
	}

	print "\nNow for the bad news.\n\n";
	printf "At today's stock price of %s, you'll walk away from %s:\n\n", format_usd($quote), 
	        format_usd($total_unvested);

    # Then subtract the value of each vesting date from the total unvested.
	foreach my $vesting_date (sort {$a cmp $b} keys %vesting_map) {
		printf "\tIf you quit before %s, you'll lose %s.\n", $vesting_date, format_usd($total_unvested);
		$total_unvested = $total_unvested - ($vesting_map{$vesting_date} * $quote);
	}

    # millionaire - both based on today's vested & if you make it to the end.
    # No point doing this if the user is already a fucking bastard millionaire.
	if ($vested_worth < ONE_MILLION_DOLLARS) {
		print "\nWanna be a millionaire?\n\n";

		my $today_mil_quote = ONE_MILLION_DOLLARS / $vested_shares;
		printf "\tIf you quit today, you would need $ticker to be at %s.\n", format_usd($today_mil_quote);

		my $later_mil_quote = ONE_MILLION_DOLLARS / ($unvested_shares + $vested_shares);
		printf "\tIf you make it to the end, you need $ticker to be at %s.\n", format_usd($later_mil_quote);

		printf "\tToday, unfortunately, $ticker is at %s\n\n", format_usd($quote);
	}

    # now this is just cheeky
	if ($vested_worth >= ONE_MILLION_DOLLARS        ) {
		print "\nYOU MADE IT! Now go live your live of leisure and luxury!\n";
	} else {
		print "Keep on workin'. Hang in there, little buddy...you'll make it eventually!\n";
	}
}

#
# Shamelessly stolen from:
# http://vishnuagrawal.blogspot.com/2008/10/perl-formatting-number-to-currency.html
#
sub format_usd {
	my $number = sprintf "%.2f", shift @_;

       # Add one comma each time through the do-nothing loop
       1 while $number =~ s/^(-?\d+)(\d\d\d)/$1,$2/;

       # Put the dollar sign in the right place
       $number =~ s/^(-?)/$1\$/;

       return $number;
}

#
# Get the raw html from Google but don't do any parsing.
#
sub get_raw_html {
	my $ticker = shift;

    # Mobile site should be easier to parse
	# Should factor Google vs Yahoo into an option
#	my $base_url = 'http://www.google.com/m/?q=';
	my $base_url = 'http://m.yahoo.com/w/yfinance/quote/';
	my $url = $base_url.$ticker;

    # Putting these into their own subroutines
    # in case I need to do anything sophisticated.
	my $ua = _get_user_agent();
	my $request = _make_request($url);

	my $result = $ua->request($request);

	if ($result->is_success) {
		return $result->content;
	} else {
		print "An unknown error occurred:\n";
		print $result->status_line, "\n";
		exit;
	}
}

#
# This is where the magic happens. Or something.
#
sub parse_google_html {
	my $html = shift;
	my $quote = '0.00';

	# Google:
    # <br/>Xn.Xn +/-Xn.Xn (+/-Xn.Xn%) <br/>
    # <br/>135.54 -0.95 (-0.70%) <br/>
    # <br/>127.94 +0.59 (0.46%) <br/>
	# Here be dragons:
	if ($html =~ /(\<br\/\>\d+\.\d+\s(\+|\-)\d+\.\d+\s\((\-?)\d+\.\d+\%\)\s\<br\/>)/g ) {
		$quote = $1;
    }

    # if we got a successful quote, prune it further.
    # There is likely a more elegant way to do this.
	if ($quote ne '0.00') {
		$quote =~ s/\<br\/>//g;
		my $quote_to_return;
        if ($quote =~ /(^\d+\.\d+)\s./) {
			$quote_to_return = $1;
            $quote = $quote_to_return;
        }
	}

	return $quote;
}

sub parse_html {
	my $html = shift;
	my $quote = '0.00';

	# <span class="w"><b>157.78</b></span>
	# My eyes, they bleed...
	if ($html =~ /(\<span class\=\"w\"\>\<b\>((\-?)\d+\.\d+)\<\/b\>\<\/span\>)/g ) {
		$quote = $2;
	} 

	return $quote;
}

sub _get_user_agent {
	my $ua = LWP::UserAgent->new;
	return $ua;
}

sub _make_request {
	my $url = shift;
	my $req = HTTP::Request->new(GET => $url);
	return $req;
}

sub usage_and_exit {
       die "$0 --ticker=[ticker symbol] (--value=x.xx)\n"
}

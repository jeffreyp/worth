# worth.pl

Has anyone employed at a dot com NOT written a variant of this script?

## Usage

Usage:
  worth.pl --ticker=[ticker symbol] --value=x.xx --source=[google|yahoo]

## Notes

Given a stock ticker symbol, scrape the current price from
Yahoo/Google and figure out how much money you'd walk away from if you
quit.

Yahoo is the default. Google isn't working as of now.

Value is an optional parameter that will probably just make you feel bad.

This works quite well for the restricted stock units granted by my
current employer. You simply need to configure the number of shares
currently held, and your vesting schedule.

## Dependencies

These shouldn't cause any issues, but FYI nonetheless.

Getopt::Long
libwww-perl (for LWP::UserAgent)

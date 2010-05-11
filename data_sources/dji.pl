#!/usr/bin/perl

# DJI - This produces the DJI feed for the Orbs of Approximate Data.
#
# Fetches DJI info from the Yahoo Finance CSV download link and 
# writes them out in the Orb Data Format
#
# Yahoo Finance CSV Format:
# name, last value, last trade date, last trade time, day change,
# open, day range high, day range low, volume
#
# Orb Data Format:
# $<color>,<intensity>
#
# Gains in the index are mapped to Green.  Losses are mapped to Red.
# Volume of trading it mapped to intensity.  A low intensity blue
# will be displayed when the market is closed.  A blinking blue 
# indicates that we had some problem getting or parsing the data.

use LWP::UserAgent;
use Date::Parse;

# Orb Color Values
use constant RED => 0;
use constant GREEN => 1;
use constant BLUE => 2;
use constant PURPLE => 3;
use constant AQUA => 4;

# The market must be up or down this amount to show a +/- change
$CHANGE_THRESHOLD = 20;

# Return values - All of this is work to set a color and an intensity for
# the Orbs
$color;
$intensity;

# Fetch the web page
$url = "http://download.finance.yahoo.com/d/quotes.csv?s=%5EDJI&f=sl1d1t1c1ohgv&e=.csv";
$ua = LWP::UserAgent->new();
my $request = HTTP::Request->new(GET => $url);
my $response = $ua->request($request);

# Split the CSV fields
if (!$response->is_error()) {
	my $content = $response->content();
	@fields = split /,/, $content;
} 

if ($#fields == 8) {

	# If we got the page and it split into 9 fields, then we'll assume things 
	# are still working well

	# Pull out the needed fields
	$last_time = $fields[3];
	$day_change = $fields[4];
	$volume = $fields[8];

	# The NYSE closing bell is at 4pm.  A last trade time at or after 4pm
	# means the day is over.	
	$last_time =~ /"(.+):.*/;
	$last_hour = $1;
	
	if ($last_hour == 4) {
		$color = BLUE;
		$intensity = 10;
	} else {

		if ($day_change < (-1 * $CHANGE_THRESHOLD) ) { 
			$color = RED;
		} elsif ($day_change > $CHANGE_THRESHOLD) {
			$color = GREEN;
		} else {
			$color = BLUE;
		}

		# A normal volume range is 100M - 400M.  Map these to values between
		# 0 and 100.  Map outliers to -1 or 101.
		# That measuring stick of 100M - 400M per day is spread evenly
		# across the 6.5 (round to 7) hours per day that the NYSE is open.
		# TODO: Improve the granularity here by calculating this based 
		# on minutes the market is open.
		if ($last_hour < 9) {
			$last_hour += 12;	# normalize to 24 hr time
		}
		$hours_open = $last_hour - 9;
	
		$VOLUME_LOW = (100000000 / 7) * $hours_open;
		$VOLUME_HIGH = (400000000 / 7) * $hours_open;
		$intensity = int( ($volume - $VOLUME_LOW) / 
					( ($VOLUME_HIGH - $VOLUME_LOW) / 100) );

		# Set up a base line so the orb is always glowing a bit
		if ($intensity < 10) { 
			$intensity = 10;
		}
	}
		
} else {

	# Otherwise, there was some problem either with fetching the data
	# or with parsing it.  Indicate an error to the Orb
	$color = BLUE;
	$intensity = 101;	# Blink - indicate an error
}


# And do the output.
print '$' . "$color,$intensity\n";


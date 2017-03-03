#!/usr/bin/perl
=pod

@filename webharvest.pl
@author Jason Willmore, jason.willmore@wsu.edu
@created 2/28/2016

This file is a Perl script that scours some specific web site for images, 
links, and uniquely referenced sites. The script writes an HTML file 
to STDOUT which contains threes HTML tables.

=cut

use strict;

my $site = "http://www.vancouver.wsu.edu";
my @image_urls;
my @link_urls;

my $date_time = localtime;


open(my $fh, "curl $site |") or die "$!\n";

# Match and capture
for (<$fh>) {
	chomp();
	# Match and capture desired links
	while (/(?: src=")([^"]*)/gi) {
		my $url = $1;
		$url = $site . $url unless $url =~ /^http:/i;
		if (m{\.(bmp|jpg|jpeg|gif|png|tif|tiff)}i) {
			push @image_urls, $url;
		}
	}

	while (/(?: href=")([^"]*)/gi) {
		my $url = $1;
		$url = $site . $url unless $url =~ /^http:/i;
		if($url =~ m{\.(bmp|jpg|jpeg|gif|png|tif|tiff)}i) {
			push @image_urls, $url;
		}
		elsif(!(m{\.([asp|css])}i)) {
			push @link_urls, $url;
		}
	}
}
close $fh;


# Extract unique site names
my %sites;
for (@link_urls) {
	$sites{$1} = 1 if m{https?://([^/\%\:]*)}i;
}
	


print <<"EOF";
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>$site</title>
  </head>
  <body>
    <h2>$site</h2>
    <h2>$date_time</h2>
    	
  <table>
EOF


for (@image_urls){
	# Create thumbnails
	if (m{.*/(.*)\..*$}){
		my $thumb = "$1.png";
		unless (-e $thumb) {
			my $cmd = "curl '$_' | convert - -resize 50x50 '$thumb'";
			print STDERR "$cmd I am unhappy... \n";
			next unless system($cmd) == 0;
		}
		print "<tr><td><a href=\"$_\"><img src = \"$thumb\"/></a></td></tr>";
	}
}

for (@link_urls) {
	print "<tr><td><a href=\"$_\">$_</a></td></tr>";
}

print "</table></body></html>";




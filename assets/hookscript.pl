#!/usr/bin/perl

use strict;
use warnings;
use Sys::Hostname;

print "GUEST HOOK: " . join(' ', @ARGV). "\n";

my $vmid = shift;
my $phase = shift;
my $anhost = hostname;

if ($phase eq 'pre-start') {
    print "$vmid is starting.\n";
} elsif ($phase eq 'post-start') {
    print "$vmid started, executing network script.\n";
} elsif ($phase eq 'pre-stop') {
    print "$vmid will be stopped.\n";
} elsif ($phase eq 'post-stop') {
    print "$vmid stopped. Doing cleanup.\n";
} else {
    die "got unknown phase '$phase'\n";
}

exit(0);

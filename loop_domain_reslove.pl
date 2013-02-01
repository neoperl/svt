#!/usr/bin/perl -w

use strict;

my $fqdn=$ARGV[0];
my $dns_server=$ARGV[1];
#my $ping=`ping -n 1 $dns`;


while (1) {
        if (defined $dns_server) {
                open( AF, "nslookup $fqdn $dns_server |" ) or die "don't open $!";
        } else {
                open( AF, "nslookup $fqdn |" ) or die "not open $!";
        }
        foreach my $result (<AF>) {
                if ( $result =~ /Address.*: / ) {
                print "$result";
                sleep 3;
                }
        }

        close AF;
}

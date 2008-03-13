#!perl -w

print "1..2\n";

use strict;
use Catalyst::SmartURI;
use Catalyst::SmartURI::URL;

my $b = Catalyst::SmartURI::URL->new("http://www/");

my $u1 = Catalyst::SmartURI::URL->new("foo", $b);
my $u2 = $u1->clone;

$u1->base("http://yyy/");

#use Data::Dump; Data::Dump::dump($b, $u1, $u2);

print "not " unless $u1->abs->as_string eq "http://yyy/foo";
print "ok 1\n";

print "not " unless $u2->abs->as_string eq "http://www/foo";
print "ok 2\n";

#!perl -w

print "1..6\n";

# Test mixing of Catalyst::SmartURI and Catalyst::SmartURI::WithBase objects
use Catalyst::SmartURI;
use Catalyst::SmartURI::WithBase;
use Catalyst::SmartURI::URL;

$str = "http://www.sn.no/";
$rel = "path/img.gif";

$u  = Catalyst::SmartURI->new($str);
$uw = Catalyst::SmartURI::WithBase->new($str, "http:");
$uu = Catalyst::SmartURI::URL->new($str);

sub Dump
{
   require Data::Dumper;
   print Data::Dumper->Dump([$a, $b, $c, $d], [qw(a b c d)]);
}

$a = Catalyst::SmartURI->new($rel, $u);
$b = Catalyst::SmartURI->new($rel, $uw);
$c = Catalyst::SmartURI->new($rel, $uu);
$d = Catalyst::SmartURI->new($rel, $str);

#Dump();
print "not " unless $a->isa("Catalyst::SmartURI") &&
                    ref($b) eq ref($uw) &&
                    ref($c) eq ref($uu) &&
                    $d->isa("Catalyst::SmartURI");
print "ok 1\n";

print "not " if $b->base && $c->base;
print "ok 2\n";

$a = Catalyst::SmartURI::URL->new($rel, $u);
$b = Catalyst::SmartURI::URL->new($rel, $uw);
$c = Catalyst::SmartURI::URL->new($rel, $uu);
$d = Catalyst::SmartURI::URL->new($rel, $str);

print "not " unless ref($a) eq "Catalyst::SmartURI::URL" &&
                    ref($b) eq "Catalyst::SmartURI::URL" &&
                    ref($c) eq "Catalyst::SmartURI::URL" &&
                    ref($d) eq "Catalyst::SmartURI::URL";
print "ok 3\n";

print "not " unless ref($b->base) eq ref($uw) &&
                    $b->base eq $uw &&
                    ref($c->base) eq ref($uu) &&
                    $c->base eq $uu &&
                    $d->base eq $str;
print "ok 4\n";



$a = Catalyst::SmartURI->new($uu, $u);
$b = Catalyst::SmartURI->new($uu, $uw);
$c = Catalyst::SmartURI->new($uu, $uu);
$d = Catalyst::SmartURI->new($uu, $str);

#Dump();
print "not " unless ref($a) eq ref($b) &&
                    ref($b) eq ref($c) &&
                    ref($c) eq ref($d) &&
                    ref($d) eq ref($u);
print "ok 5\n";

$a = Catalyst::SmartURI::URL->new($u, $u);
$b = Catalyst::SmartURI::URL->new($u, $uw);
$c = Catalyst::SmartURI::URL->new($u, $uu);
$d = Catalyst::SmartURI::URL->new($u, $str);

print "not " unless ref($a) eq "Catalyst::SmartURI::URL" &&
                    ref($b) eq "Catalyst::SmartURI::URL" &&
                    ref($c) eq "Catalyst::SmartURI::URL" &&
                    ref($d) eq "Catalyst::SmartURI::URL";
print "ok 6\n";

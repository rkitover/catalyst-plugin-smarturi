#!perl -w

use Catalyst::SmartURI;
use Catalyst::SmartURI::file;
$URI::file::DEFAULT_AUTHORITY = undef;

@tests =  (
[ "file",          "unix",       "win32",         "mac" ],
#----------------  ------------  ---------------  --------------
[ "file://localhost/foo/bar",
	           "!/foo/bar",  "!\\foo\\bar",   "!foo:bar", ],
[ "file:///foo/bar",
	           "!/foo/bar",  "!\\foo\\bar",   "!foo:bar", ],
[ "file:/foo/bar", "/foo/bar",   "\\foo\\bar",    "foo:bar", ],
[ "foo/bar",       "foo/bar",    "foo\\bar",      ":foo:bar",],
[ "file://foo/bar","!//foo/bar", "\\\\foo\\bar",  "!foo:bar"],
[ "file://a:/",    "!//a:/",     "!A:\\",          undef],
[ "file:/",        "/",          "\\",             undef],
[ "file://A:relative/", "!//A:relative/", "A:",    undef],
[ ".",             ".",          ".",              ":"],
[ "..",            "..",         "..",             "::"],
[ "%2E",           "!.",          "!.",            ":."],
[ "../%2E%2E",     "!../..",      "!..\\..",       "::.."],
);
if ($^O eq "MacOS") {
@extratests = (
[ "../..",        "../..",         "..\\..",           ":::"],
[ "../../",       "../../",        "..\\..\\",         "!:::"],
[ "file:./foo.bar", "!./foo.bar",    "!.\\foo.bar",       "!:foo.bar"],
[ "file:/%2Ffoo/bar", undef,      undef,           "/foo:bar"],
[ "file:/.%2Ffoo/bar", undef,      undef,           "./foo:bar"],
[ "file:/fee/.%2Ffoo%2Fbar", undef,      undef,           "fee:./foo/bar"],
[ "file:/.%2Ffoo%2Fbar/", undef,      undef,           "./foo/bar:"],
[ "file:/.%2Ffoo%2Fbar", undef,      undef,           "!./foo/bar:"],
[ "file:/%2E%2E/foo",   "!/../foo",   "!\\..\\foo" , "..:foo"],
[ "file:/bar/%2E/foo", "!/bar/./foo",  "!\\bar\\.\\foo", "bar:.:foo"],
[ "file:/foo/../bar",  "/foo/../bar",  "\\foo\\..\\bar", "foo::bar"],
[ "file:/a/b/../../c/d",  "/a/b/../../c/d",  "\\a\\b\\..\\..\\c\\d", "a:b:::c:d"],
);
  push(@tests,@extratests);
}

@os = @{shift @tests};
shift @os;  # file

my $num = @tests;
print "1..$num\n";

$testno = 1;

for $t (@tests) {
   my @t = @$t;
   my $file = shift @t;
   my $err;

   my $u = Catalyst::SmartURI->new($file, "file");
   my $i = 0;
   for $os (@os) {
       my $f = $u->file($os);
       my $expect = $t[$i];
       $f = "<undef>" unless defined $f;
       $expect = "<undef>" unless defined $expect;
       my $loose;
       $loose++ if $expect =~ s/^!//;
       if ($expect ne $f) {
           print "Catalyst::SmartURI->new('$file', 'file')->file('$os') ne $expect, but $f\n";
           $err++;
       }
       if (defined($t[$i]) && !$loose) {
	   $u2 = Catalyst::SmartURI::file->new($t[$i], $os);
           unless ($u2->as_string eq $file) {
              print "Catalyst::SmartURI::file->new('$t[$i]', '$os') ne $file, but $u2\n";
              $err++;
           }
       }
       $i++;
   }
   print "not " if $err;
   print "ok $testno\n";
   $testno++;
}
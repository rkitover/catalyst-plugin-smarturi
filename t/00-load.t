#!perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::SmartURI' );
}

diag( "Testing Catalyst::Plugin::SmartURI $Catalyst::Plugin::SmartURI::VERSION, Perl $], $^X" );

# vim: expandtab shiftwidth=4 ts=4 tw=80:

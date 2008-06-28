use strict;
use warnings;

use Test::More tests => 1;

{
    package MyURI;

    use base 'URI::SmartURI';

    sub mtfnpy {
        my $uri = shift;
        $uri->query_form([ $uri->query_form, qw(foo bar) ]);
        $uri
    }

    package TestApp;

    use Catalyst 'SmartURI';

    sub foo : Global {
        my ($self, $c) = @_;
        $c->res->output($c->uri_for('/foo')->mtfnpy)
    }

    __PACKAGE__->config->{'Plugin::SmartURI'}{uri_class} = 'MyURI';
    __PACKAGE__->setup;
}

use Catalyst::Test 'TestApp';

is(get('/foo'), 'http://localhost/foo?foo=bar', 'configured uri_class');

# vim: expandtab shiftwidth=4 ts=4 tw=80:

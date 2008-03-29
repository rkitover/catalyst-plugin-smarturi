use strict;
use warnings;

use Test::More tests => 6;

{
    package MyURI;

    use base 'Catalyst::SmartURI';

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

    __PACKAGE__->config->{smarturi}{uri_class} = 'MyURI';
    __PACKAGE__->setup;
}

BEGIN {
    MyURI->import;
    use_ok('MyURI::URL')
}

is(MyURI::URL->new('http://search.cpan.org/~lwall/')->path,
    '/~lwall/', 'Magic import');

ok(my $uri = MyURI->new('http://www.catalystframework.org/calendar',
                    { reference => 'http://www.catalystframework.org/' }),
                    'new');

is($uri->mtfnpy,
   'http://www.catalystframework.org/calendar?foo=bar', 'new method');

is($uri->reference, 'http://www.catalystframework.org/', 'old method');

use Catalyst::Test 'TestApp';

is(get('/foo'), 'http://localhost/foo?foo=bar', 'configured uri_class');

# vim: expandtab shiftwidth=4 ts=4 tw=80:

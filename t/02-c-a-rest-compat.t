#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

SKIP: {

skip 'Catalyst::Action::REST not installed', 1 if eval 'use Catalyst::Action::REST', $@;

{
    package TestApp;

    use Catalyst 'SmartURI';

    sub foo : Global ActionClass('REST') {}

    sub foo_GET {
        my ($self, $c) = @_;

# should break if request_class is not set correctly
        $c->req->accepted_content_types;

        $c->res->redirect($c->uri_for('/foo'));
    }

    __PACKAGE__->setup();
}

use Catalyst::Test 'TestApp';

is(request('/foo')->header('location'), '/foo',
    'redirect location from C::A::REST');

}

# vim: expandtab shiftwidth=4 ts=4 tw=80:

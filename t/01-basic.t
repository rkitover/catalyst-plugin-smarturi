#!perl -T

use strict;
use warnings;
use Test::More tests => 6;

{
    package TestApp;

    use Catalyst qw/SmartURI/;

    sub test_uri_for_redirect : Global {
        my ($self, $c) = @_;
        $c->res->redirect($c->uri_for('/test_uri_for_redirect'));
    }

    sub test_req_uri_with : Global {
        my ($self, $c) = @_;
        $c->res->output($c->req->uri_with({
             the_word_that_must_be_heard => 'mtfnpy' 
        })); 
    }

    sub test_uri_object : Global {
        my ($self, $c) = @_;
        $c->res->output($c->uri_for('/test_uri_object')->path);
    }

    sub per_request : Global {
        my ($self, $c) = @_;
        $c->uri_disposition('relative');
        $c->res->output($c->uri_for('/dummy'));
    }

    sub host_header : Global {
        my ($self, $c) = @_;
        $c->req->header(Host => 'www.dongs.com');
        $c->uri_disposition('host-header');
        $c->res->output($c->uri_for('/dummy'));
    }


    sub host_header_with_port : Global {
        my ($self, $c) = @_;
        $c->req->header(Host => 'www.hlagh.com:8080');
        $c->uri_disposition('host-header');
        $c->res->output($c->uri_for('/dummy'));
    }

    sub dummy : Global {}

    __PACKAGE__->config->{'Plugin::SmartURI'}{disposition} = 'hostless';
    __PACKAGE__->setup();
}

use Catalyst::Test 'TestApp';

is(request('/test_uri_for_redirect')->header('location'),
    '/test_uri_for_redirect', 'redirect location');

is(get('/per_request'), 'dummy', 'per-request disposition');

is(get('/test_req_uri_with'),
    '/test_req_uri_with?the_word_that_must_be_heard=mtfnpy',
    '$c->req->uri_with test, and disposition reset');

is(get('/test_uri_object'), '/test_uri_object',
    'URI objects are functional');

is(get('/host_header'), 'http://www.dongs.com/dummy',
    'host-header disposition');

is(get('/host_header_with_port'), 'http://www.hlagh.com:8080/dummy',
    'host-header disposition with port');

# vim: expandtab shiftwidth=4 ts=4 tw=80:

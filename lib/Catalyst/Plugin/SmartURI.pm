package Catalyst::Plugin::SmartURI;

use strict;
use warnings;
use base qw/Class::Accessor::Fast Class::Data::Inheritable/;

=head1 NAME

Catalyst::Plugin::SmartURI - Configurable URIs for Catalyst

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    smarturi:
        disposition: hostless # application-wide

    $c->uri_disposition('absolute'); # per request

    <a href="[% c.uri_for('/foo').relative %]" ...

Configure whether $c->uri_for and $c->req->uri_with return absolute, hostless or
relative URIs and/or configure which URI class to use, on an application or
request basis.

This is useful in situations where you're for example, redirecting to a lighttpd
from a firewall rule, instead of a real proxy, and you want your links and
redirects to still work correctly.

=head1 DESCRIPTION

This plugin allows you to configure, on a application and per-request basis,
what URI class $c->uri_for and $c->req->uri_with use, as well as whether the
URIs they produce are absolute, hostless or relative.

To use your own URI class, just subclass L<URI::SmartURI> and set
uri_class, or write a class that follows the same interface.

This plugin installs a custom $c->request_class, however it does so in a way
that won't break if you've already set $c->request_class yourself (thanks mst!).

There will be a slight performance penalty for your first few requests, due to
the way L<URI::SmartURI> works, but after that you shouldn't notice
it. The penalty is considerably smaller in perl 5.10+.

=head1 CONFIGURATION

In myapp.yml:

    smarturi:
        dispostion: absolute
        uri_class: 'URI::SmartURI'

=over

=item disposition

One of 'absolute', 'hostless' or 'relative'. Defaults to 'absolute'.

=item uri_class

The class to use for URIs, defaults to L<URI::SmartURI>.

=back

=head1 PER REQUEST

    package MyAPP::Controller::RSSFeed;

    ...

    sub begin : Private {
        my ($self, $c) = @_;

        $c->uri_class('Your::URI::Class::For::Request');
        $c->uri_disposition('absolute');
    }

=over

=item $c->uri_disposition('absolute'|'hostless'|'relative')

Set URI disposition to use for the duration of the request.

=item $c->uri_class($class)

Set the URI class to use for $c->uri_for and $c->req->uri_with for the duration
of the request.

=back

=head1 EXTENDING

$c->prepare_uri actually creates the URI, you can overload that to do as you
please in your own plugins.

=cut

use Class::C3;
use Class::C3::Componentised;

__PACKAGE__->mk_accessors(qw/uri_disposition uri_class/);

my $context; # keep a copy for the Request class to use

sub uri_for {
    my $c = shift;

    $c->prepare_uri($c->next::method(@_))
}

{
    package Catalyst::Request::SmartURI;
    use base 'Catalyst::Request';

    sub uri_with {
        my $req = shift;

        $context->prepare_uri($req->next::method(@_))
    }
}

sub setup {
    my $app    = shift;
    my $config = $app->config->{smarturi};

    $config->{uri_class}   ||= 'URI::SmartURI';
    $config->{disposition} ||= 'absolute';

    my $request_class = $app->request_class;

    unless ($request_class->isa('Catalyst::Request::SmartURI')) {
        my $new_request_class = $app.'::Request::SmartURI';
        Class::C3::Componentised->inject_base(
            $new_request_class,
            'Catalyst::Request::SmartURI',
            $request_class
        );
        Class::C3::reinitialize();

        $app->request_class($new_request_class);
    }

    $app->next::method(@_)
}

sub prepare_uri {
    my ($c, $uri)   = @_;
    my $disposition = $c->uri_disposition;

    eval 'require '.$c->uri_class;

    $c->uri_class->new($uri, { reference => $c->req->uri })->$disposition
}

# Reset accessors to configured values at beginning of request.
sub prepare {
    my $app    = shift;
    my $config = $app->config->{smarturi};

# Also save a copy of the context for the Request class to use.
    my $c = $context = $app->next::method(@_);

    $c->uri_class($config->{uri_class});
    $c->uri_disposition($config->{disposition});

    $c
}

=head1 SEE ALSO

L<URI::SmartURI>, L<Catalyst>, L<URI>

=head1 AUTHOR

Rafael Kitover, C<< <rkitover at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-smarturi at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-SmartURI>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::SmartURI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-SmartURI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-SmartURI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-SmartURI>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-SmartURI>

=back

=head1 ACKNOWLEDGEMENTS

from #catalyst:

vipul came up with the idea

mst came up with the design and implementation details for the current version

kd reviewed my code and offered suggestions

=head1 TODO

I'd like to extend on L<Catalyst::Plugin::RequireSSL>, and make a plugin that
rewrites URIs for actions with an SSL attribute.

Make a disposition that is based on the Host header.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 Rafael Kitover

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::SmartURI

# vim: expandtab shiftwidth=4 ts=4 tw=80:

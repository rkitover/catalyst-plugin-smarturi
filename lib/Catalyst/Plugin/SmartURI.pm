package Catalyst::Plugin::SmartURI;

use strict;
use warnings;
use parent 'Class::Accessor::Fast';

use Class::C3;
use Class::C3::Componentised;
use Scalar::Util 'weaken';
use Catalyst::Exception ();

__PACKAGE__->mk_accessors(qw/uri_disposition uri_class/);

my $context; # keep a copy for the Request class to use

my ($conf_disposition, $conf_uri_class); # configured values

=head1 NAME

Catalyst::Plugin::SmartURI - Configurable URIs for Catalyst

=head1 VERSION

Version 0.027

=cut

our $VERSION = '0.027';

=head1 SYNOPSIS

In your .conf:

    <Plugin::SmartURI>
        disposition host-header   # application-wide
        uri_class   URI::SmartURI # by default
    </Plugin::SmartURI>

Per request:

    $c->uri_disposition('absolute');

Methods on URIs:

    <a href="[% c.uri_for('/foo').relative %]" ...

=head1 DESCRIPTION

Configure whether $c->uri_for and $c->req->uri_with return absolute, hostless or
relative URIs, or URIs based on the 'Host' header. Also allows configuring which
URI class to use. Works on application-wide or per-request basis.

This is useful in situations where you're for example, redirecting to a lighttpd
from a firewall rule, instead of a real proxy, and you want your links and
redirects to still work correctly.

To use your own URI class, just subclass L<URI::SmartURI> and set
uri_class, or write a class that follows the same interface.

This plugin installs a custom $c->request_class, however it does so in a way
that won't break if you've already set $c->request_class yourself, ie. by using
L<Catalyst::Action::REST> (thanks mst!).

There is a minor performance penalty in perls older than 5.10, due to
L<Class::C3>, but only at initialization time.

=head1 METHODS

=head2 $c->uri_for

=head2 $c->req->uri_with

Returns a $c->uri_class object (L<URI::SmartURI> by default) in the configured
$c->uri_disposition.

=head2 $c->req->uri

Returns a $c->uri_class object. If the context hasn't been prepared yet, uses
the configured value for uri_class.

$c->req->uri->relative will be relative to $c->req->base.

=head2 $c->req->referer

Returns a $c->uri_class object for the referer (or configured uri_class if
there's no context) with reference set to $c->req->uri if it comes from
$c->req->base.

In other words, if referer is your web server, you can do
$c->req->referer->relative and it will do the right thing.

=head1 CONFIGURATION

In myapp.conf:

    <Plugin::SmartURI>
        dispostion absolute
        uri_class  URI::SmartURI
    </Plugin::SmartURI>

=over

=item disposition

One of 'absolute', 'hostless', 'relative' or 'host-header'.  Defaults to
'absolute'.

The special disposition 'host-header' uses the value of your 'Host:' header.

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

=item $c->uri_disposition('absolute'|'hostless'|'relative'|'host-header')

Set URI disposition to use for the duration of the request.

=item $c->uri_class($class)

Set the URI class to use for $c->uri_for and $c->req->uri_with for the duration
of the request.

=back

=head1 EXTENDING

$c->prepare_uri actually creates the URI, which you can override.

=cut

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

    sub uri {
        my $req = shift;

        my $uri_class = $context ? $context->uri_class : $conf_uri_class;

        $uri_class->new(
            $req->next::method(@_),
            { reference => $req->base }
        )
    }

    sub referer {
        my $req = shift;

        my $uri_class = $context ? $context->uri_class : $conf_uri_class;
        my $referer   = $req->next::method(@_) || '';
        my $base      = $req->base;
        my $uri       = $req->uri;

        if ($referer =~ /^$base/) {
            return $uri_class->new($referer, { reference => $uri })
        } else {
            return $uri_class->new($referer);
        }
    }
}

sub setup {
    my $app    = shift;
    my $config =$app->config->{'Plugin::SmartURI'} || $app->config->{smarturi};

    ($conf_uri_class, $conf_disposition) = @$config{qw/uri_class disposition/};
    $conf_uri_class   ||= 'URI::SmartURI';
    $conf_disposition ||= 'absolute';

    unless (do { no strict 'refs'; %{$conf_uri_class.'::'} }) {
        eval "require $conf_uri_class";
        Catalyst::Exception->throw(
            message => "Could not load configured uri_class $conf_uri_class: $@"
        ) if $@;
    }

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

{
my %loaded;

sub prepare_uri {
    my ($c, $uri)   = @_;
    my $disposition = $c->uri_disposition || $conf_disposition;
    my $uri_class   = $c->uri_class       || $conf_uri_class;
# Need the || for $c->welcome_message, otherwise initialization works fine.

    unless ($loaded{$uri_class} || do { no strict 'refs'; %{$uri_class.'::'} }) {
        eval "require $uri_class";
        if ($@) {
            Catalyst::Exception->throw(
                message => "Could not load configured uri_class $conf_uri_class: $@"
            );
        } else {
            $loaded{$uri_class}++
        }
    }

    my $res;
    if ($disposition eq 'host-header') {
      $res = $uri_class->new($uri, { reference => $c->req->uri })->absolute;
      my $host = $c->req->header('Host');
      $host =~ s/:(\d+)$//;

      my $port = $1;
      $port = '' if $c->req->uri->scheme eq 'http'  && $port == 80;
      $port = '' if $c->req->uri->scheme eq 'https' && $port == 443;

      $res->host($host);
      $res->port($port) if $port;
    } else {
      $res = $uri_class->new($uri, { reference => $c->req->uri })->$disposition
    }

    $res
}
}

# Reset accessors to configured values at beginning of request.
sub prepare {
    my $app = shift;

# Also save a copy of the context for the Request class to use.
    my $c = $context = $app->next::method(@_);
    weaken $context;

    $c->uri_class($conf_uri_class);
    $c->uri_disposition($conf_disposition);

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

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 Rafael Kitover

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::SmartURI

# vim: expandtab shiftwidth=4 tw=80:

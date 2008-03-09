package Catalyst::Plugin::SmartURI;

use strict;
use warnings;

=head1 NAME

Catalyst::Plugin::SmartURI - Configurable URI disposition

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Configure whether $c->uri_for and $c->req->uri_with return absolute, hostless or
relative URIs.

This is useful in situations where you're for example, redirecting to a lighttpd
from a firewall rule, instead of a real proxy, and you want your links and
redirects to still work correctly.

In myapp.yml:

    smarturi:
        default_disposition: hostless

In MyApp.pm:

    package MyApp;
    ...
    use Catalyst qw/SmartURI/;
    ...

=cut

use Class::C3;
use Class::C3::Componentised;
use Catalyst::SmartURI;

sub uri_for {
    my $c = shift;

    Catalyst::SmartURI->new($c->next::method(@_))->hostless;
}

{
    package Catalyst::Request::SmartURI;
    use base 'Catalyst::Request';

    sub uri_with {
        my $req = shift;

        Catalyst::SmartURI->new($req->next::method(@_))->hostless;
    }
}

sub setup_engine {
    my $app = shift;

    my $new_request_class = $app.'::Request::SmartURI';
    Class::C3::Componentised->inject_base(
        $new_request_class,
        'Catalyst::Request::SmartURI',
        $app->request_class
    );
    Class::C3::reinitialize();

    $app->request_class($new_request_class);

    $app->next::method(@_)
}

=head1 AUTHOR

Rafael Kitover, C<< <rkitover at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-relativepaths at rt.cpan.org>, or through the web
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

mst came up with the design and implementation notes for the current version

kd reviewed my code and offered suggestions

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 Rafael Kitover

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::SmartURI

# vim: expandtab shiftwidth=4 ts=4 tw=80:

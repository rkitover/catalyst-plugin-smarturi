package Catalyst::SmartURI;

use strict;
use warnings;

=head1 NAME

Catalyst::SmartURI - URIs with extra sugar

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $uri = Catalyst::SmartURI->new('http://catalyst.perl.org/calendar');

    my $hostless= $uri->hostless; # stringifies to '/catalyst.perl.org/calendar'

=cut

use Class::C3;
use Class::C3::Componentised;
use base 'URI';

sub new {
    my $class = shift;

    # URI objects are not really URI objects, but URI::http etc.
    my $self = $class->next::method(@_);

    my $uri_class      = ref $self;
    (my $new_uri_class = $uri_class) =~ s/^URI::/Catalyst::SmartURI::/;

    no strict 'refs';

    unless (%{$new_uri_class.'::'}) {
        Class::C3::Componentised->inject_base(
            $new_uri_class,
            'Catalyst::SmartURI::__BASE__',
            $uri_class
        );   
        Class::C3::reinitialize();
    }

    bless $self, $new_uri_class;
}

{
    package Catalyst::SmartURI::__BASE__;

    sub hostless {
        my $uri = shift;

        $uri->scheme('');
        $uri->host('');

        my $class = ref $uri;

        return $class->new( $uri =~ m!^/*(/.*)! );
    }
}

=head1 AUTHOR

Rafael Kitover, C<< <rkitover at cpan.org> >>

=cut

'LONG LIVE THE ALMIGHTY BUNGHOLE'; # End of Catalyst::SmartURI

# vim: expandtab shiftwidth=4 ts=4 tw=80:

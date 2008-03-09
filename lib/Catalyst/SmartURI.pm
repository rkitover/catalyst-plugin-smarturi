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

    my $hostless = $uri->hostless; # stringifies to '/catalyst.perl.org/calendar'

=cut

use Class::C3;
use Class::C3::Componentised;
use base 'URI';

sub new {
    my $class = shift;

    my $self = $class->next::method(@_);

    # URI objects are not really URI objects, but URI::http etc.
    Class::C3::Componentised->inject_base($class, ref $self);   
    Class::C3::reinitialize();

    bless $self, $class;
}

sub hostless {
    my $uri = shift;

    $uri->scheme('');
    $uri->host('');

    my $class = ref $uri;

    return $class->new( $uri =~ m!^/*(/.*)! );
};

=head1 AUTHOR

Rafael Kitover, C<< <rkitover at cpan.org> >>

=cut

1; # End of Catalyst::SmartURI

# vim: expandtab shiftwidth=4 ts=4 tw=80:

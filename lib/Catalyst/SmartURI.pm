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

use URI;
use URI::URL;
use Class::C3;
use Class::C3::Componentised;
use File::Find::Rule;
use File::Spec::Functions qw/splitpath splitdir catfile/;
use List::MoreUtils 'firstidx';
use Scalar::Util 'blessed';
use List::Util 'first';
use IO::Scalar;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_ro_accessors(qw/obj factory_class/);

# Constructors

sub new {
    my $class = shift;

    my $self = {obj => URI->new($class->deflate(@_)), factory_class => $class};

    bless $self, $class->make_uri_class(blessed $self->{obj}, 1);
}

sub new_abs {
    my $class = shift;

    my $self = {obj => URI->new_abs($class->deflate(@_)), factory_class => $class};

    bless $self, $class->make_uri_class(blessed $self->{obj}, 1);
}

sub newlocal {
    my $class = shift;

    my $self = {obj => URI::URL->newlocal($class->deflate(@_)), factory_class => $class};

    bless $self, $class->make_uri_class(blessed $self->{obj}, 1);
}

# Utilities

sub hostless {
    my $uri = shift;

    $uri->scheme('');
    $uri->host('');

    my $class = blessed $uri;

    return $class->new( $uri =~ m!^/*(/.*)! );
}

# The gory details

sub AUTOLOAD {
    use vars '$AUTOLOAD';
    my $self      = shift;
# stolen from URI sources
    my $method    = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);

    return if ! blessed $self || $method eq 'DESTROY';

    my $class     = $self->factory_class;

    my @res;
    if (wantarray) {
        @res    = $self->obj->$method($class->deflate(@_));
    } else {
        $res[0] = $self->obj->$method($class->deflate(@_));
    }
    @res = $class->inflate(@res);

    return wantarray ? @res : $res[0];
}

use overload
    '""' => sub { "".$_[0]->obj },
    '==' =>
        sub { overload::StrVal($_[0]->obj) eq overload::StrVal($_[1]->obj) },
    fallback => 1;

sub eq {
    my ($self, $other) = @_;

# Support URI::eq($first, $second) syntax. Not inheritance-safe :(
    $self = blessed $self ? $self : __PACKAGE__->new($self);

    return $self->obj->eq(ref $other eq blessed $self ? $other->obj : $other);
}

# Preload some URI classes, the ones that come in files anyway
sub import {
    no strict 'refs';
    my $class = shift;

    return if ${$class.'::__INITIALIZED__'};

# File::Find::Rule is not taint safe, and Module::Starter suggests running
# tests in taint mode. Thanks for helping me with this one Somni!!!
    {
        no warnings 'redefine';
        my $getcwd = \&File::Find::Rule::getcwd;
        *File::Find::Rule::getcwd = sub { $getcwd->() =~ m!^(.*)\z! };
        # What are portably valid characters in a directory name anyway?
    }

    my @uri_pms = File::Find::Rule->extras({untaint => 1})->file->name('*.pm')
        ->in( File::Find::Rule->extras({untaint => 1})->directory
            ->maxdepth(1)->name('URI')->in(@INC)
        );
    my @new_uri_pms;

    for (@uri_pms) {
        my ($dir, $file) = (splitpath($_))[1,2];

        my @dir          = grep $_ ne '', splitdir $dir;
        my @rel_dir      = @dir[(firstidx { $_ eq 'URI' } @dir) ..  $#dir];
        my $mod          = join '::' => @rel_dir, ($file =~ /^(.*)\.pm\z/);

        my $new_class    = $class->make_uri_class($mod, 0);

        push @new_uri_pms, catfile(split /::/, $new_class) . '.pm';
    }

# HLAGHALAGHLAGHLAGHLAGH
    push @INC, sub {
        if (first { $_ eq $_[1] } @new_uri_pms) {
            open my $fh, '<', \"1;\n";
            return $fh;
        }
    };

    Class::C3::reinitialize();

    ${$class.'::__INITIALIZED__'} = 1;
}

sub resolve_uri_class {
    my ($class, $uri_class) = @_;

    (my $new_class = $uri_class) =~ s/^URI::/${class}::/;

    return $new_class;
}

sub make_uri_class {
    my ($class, $uri_class, $re_init_c3) = @_;

    my $new_uri_class = $class->resolve_uri_class($uri_class);

    no strict 'refs';

    unless (%{$new_uri_class.'::'}) {
        Class::C3::Componentised->inject_base($new_uri_class, $class);

        *{$new_uri_class.'::new'} = sub {
            eval "require $uri_class";
            bless {
                obj => $uri_class->new($class->deflate(@_[1..$#_])),
                factory_class => $class
            }, $new_uri_class;
        };

        *{$new_uri_class.'::import'} = sub {
            eval "require $uri_class";
            if (my $code = $uri_class->can('import')) {
                splice @_, 0, 1, $uri_class;
                goto &$code;
            }
        };

        Class::C3::reinitialize() if $re_init_c3;
    }

    return $new_uri_class;
}

sub inflate {
    my $class = shift;

    map { blessed $_ ?
            bless { obj => $_, factory_class => $class },
                $class->make_uri_class(blessed $_, 1)
          :
                $_
    } @_;
}

sub deflate {
    my $class = shift;
    map { blessed $_ && $_->isa($class) ?  $_->{obj} : $_ } @_
}

=head1 AUTHOR

Rafael Kitover, C<< <rkitover at cpan.org> >>

=cut

'LONG LIVE THE ALMIGHTY BUNGHOLE'; # End of Catalyst::SmartURI

# vim: expandtab shiftwidth=4 ts=4 tw=80:

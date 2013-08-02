package Notifications::Observer;

use strict;
use warnings;

use Notifications::Dispatcher;
use Scalar::Util qw( refaddr );

sub new
    {
    my $class = shift;

    my $self = bless {}, $class;

    $self->{catchers} = {};

    return $self;
    }

sub start   { my $self = shift; Notifications::Dispatcher::add_observer( $self ); $self->{is_started} = 1; return $self; }
sub stop    { my $self = shift; Notifications::Dispatcher::remove_observer( $self ); $self->{is_started} = 0; return $self; }
sub DESTROY { my $self = shift; printf "%s died at %s line %s\n", refaddr( $self ), (caller)[1,2]; $self->stop(); }

sub observe_with
    {
    my $self  = shift;
    my %param = @_;

    @{$self->{catchers}}{ keys %param } = values %param;

    if( $self->{is_started} )
        {
        foreach my $name ( keys %param )
            {
            Notifications::Dispatcher::enqueue( $name, $self );
            }
        }

    return;
    }

sub observer_for
    {
    my $self = shift;
    my $name = shift;
    return ( $self->{catchers}{$name} or $self->{catchers}{''} );
    }

1;

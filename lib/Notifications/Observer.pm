package Notifications::Observer;

use strict;
use warnings;

use Notifications::Dispatcher;

sub new
    {
    my $class = shift;
    my $param = { @_ };
    my $self = bless {}, $class;

    $self->{dispatcher} = delete( $param->{dispatcher} ) // Notifications::Dispatcher->global_dispatcher();
    $self->{catchers}   = $param;

    $self->{dispatcher}->add_observer( $self );

    return $self;
    }

sub DESTROY
    {
    my $self = shift;
    printf "killing observer\n";
    $self->{dispatcher}->remove_observer( $self )   if $self->{dispatcher};
    return;
    }

sub observe_with
    {
    my $self = shift;
    my %param = @_;
    @{$self->{catchers}}{ keys %param } = values %param;
    return;
    }

sub observer_for
    {
    my $self = shift;
    my $name = shift;
    return ( $self->{catchers}{$name} or $self->{catchers}{''} );
    }

1;

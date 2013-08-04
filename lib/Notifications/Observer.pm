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
    $self->{callback}   = $param;

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

sub set_callbacks
    {
    my $self  = shift;
    my %param = @_;

    @{$self->{callback}}{ keys %param } = values %param;

    return;
    }

sub callback_for
    {
    my $self = shift;
    my $name = shift;
    return ( $self->{callback}{$name} or $self->{callback}{''} );
    }

1;

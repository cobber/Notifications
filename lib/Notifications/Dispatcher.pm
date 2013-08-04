package Notifications::Dispatcher;

use strict;
use warnings;

use Carp         qw( croak );
use Scalar::Util qw( refaddr weaken );

my $global_dispatcher;

BEGIN {
    $global_dispatcher = bless {}, __PACKAGE__;
}

sub new               { return $global_dispatcher; }
sub global_dispatcher { return $global_dispatcher; }

sub DESTROY { printf "killing dispatcher\n"; }

sub prepare_queue
    {
    my $self = shift;
    my $name = shift;

    # create a new queue and add all matching callbacks from all known observers
    if( not exists $self->{queue}{$name} )
        {
        $self->{queue}{$name} = {};
        foreach my $observer ( values %{$self->{observers}} )
            {
            my $callback     = $observer->callback_for( $name )  or next;
            my $observer_ref = refaddr( $observer );
            $self->{queue}{$name}{$observer_ref} = $callback;
            }
        }

    return;
    }

sub add_observer
    {
    my $self     = shift;
    my $observer = shift;

    croak( "Cannot add an undefined notifications observer" )   if not $observer;

    weaken( $self->{observers}{ refaddr( $observer ) } = $observer );

    # add new observer to all appropriate existing queues
    # Note: only add to queues that are actually needed - otherwise the catch-all concept won't work
    foreach my $name ( keys %{$self->{queue}} )
        {
        my $callback     = $observer->callback_for( $name ) or next;
        my $observer_ref = refaddr( $observer );
        $self->{queue}{$name}{$observer_ref} = $callback;
        }

    return;
    }

sub has_observers_for
    {
    my $self = shift;
    my $name = shift;
    # note: only return 0 if we have seen this name before and still have no observers for it
    return ( exists $self->{queue}{$name} and not keys %{$self->{queue}{$name}} ) ? 0 : 1;
    }

sub remove_observer
    {
    my $self     = shift;
    my $observer = shift;

    return if not $observer;

    my $observer_ref = refaddr( $observer );

    foreach my $name ( keys %{$self->{queue}} )
        {
        delete $self->{queue}{$name}{$observer_ref};
        }

    delete $self->{observers}{$observer_ref};

    return;
    }

sub send
    {
    my $self    = shift;
    my $message = shift;
    my $name    = $message->name();

    $self->prepare_queue( $name )  if not $self->{queue}{$name};

    foreach my $callback ( values %{$self->{queue}{$name}} )
        {
        $callback->( $message );
        }

    return;
    }

1;

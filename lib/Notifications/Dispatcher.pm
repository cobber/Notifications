package Notifications::Dispatcher;

use strict;
use warnings;

use Carp         qw( croak );
use Scalar::Util qw( refaddr weaken );

my $global_dispatcher;

BEGIN
    {
    $global_dispatcher = bless {}, __PACKAGE__;
    }

sub new               { return $global_dispatcher; }
sub global_dispatcher { return $global_dispatcher; }

sub queue
    {
    my $self = shift;
    my $name = shift;

    # create a new queue and add all matching callbacks from all known observers
    if( not exists $self->{queue}{$name} )
        {
        $self->{queue}{$name} = {};
        foreach my $observer ( values %{$self->{observers}} )
            {
            $self->enqueue( $name, $observer );
            }
        }

    return $self->{queue}{$name};
    }

sub enqueue
    {
    my $self     = shift;
    my $name     = shift;
    my $observer = shift;

    my $observer_ref = refaddr( $observer );
    my $queue        = $self->queue( $name );

#     printf "enqueuing: %s => %-7s %s\n", $observer_ref, "'$name'", join( ", ", map { sprintf( "[ %s => %s ]", $_, $queue->{$_} ) } sort keys %{$queue} );

    if( my $callback = $observer->callback_for( $name ) )
        {
        $queue->{$observer_ref} = $callback;
        }
    else
        {
        $self->dequeue( $name, $observer_ref );
        }

#     printf "enqueued: %s => %-7s %s\n", $observer_ref, "'$name'", join( ", ", map { sprintf( "[ %s => %s ]", $_, $queue->{$_} ) } sort keys %{$queue} );

    return;
    }

sub dequeue
    {
    my $self     = shift;
    my $name     = shift;
    my $observer = shift;

    my $queue        = $self->queue( $name );
    my $observer_ref = ref( $observer ) ? refaddr( $observer ) : $observer;

    delete $queue->{$observer_ref};

#     printf "dequeued: %s <= %-7s %s\n", $observer_ref, "'$name'", join( ", ", map { sprintf( "[ %s => %s ]", $_, $queue->{$_} ) } sort keys %{$queue} );

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
        $self->enqueue( $name, $observer );
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
        $self->dequeue( $name, $observer );
        }

    delete $self->{observers}{$observer_ref};

    return;
    }

sub send
    {
    my $self    = shift;
    my $message = shift;
    my $name    = $message->name();

    my $queue = $self->queue( $name );

    foreach my $observer_ref ( keys %{$queue} )
        {
        if( not $self->{observers}{$observer_ref} )
            {
            # clean up an observer that was destroyed - can happen because we're using weak refs
            $self->dequeue( $name, $observer_ref );
            next;
            }

        $queue->{$observer_ref}( $message );
        }

    return;
    }

1;

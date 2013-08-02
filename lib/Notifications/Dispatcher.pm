package Notifications::Dispatcher;

use strict;
use warnings;

use Scalar::Util qw( refaddr weaken );
use YAML;

my $global_dispatcher;

BEGIN
    {
#     printf "setting up global dispatcher...\n";
    $global_dispatcher = bless {}, __PACKAGE__;
    }

sub queue
    {
    my $name = shift;

    if( not exists $global_dispatcher->{queue}{$name} )
        {
        $global_dispatcher->{queue}{$name} = {};
#         printf "setting up new queue for '%s'...\n%s...\n", $name, Dump( $global_dispatcher );
        foreach my $observer ( grep { defined } values %{$global_dispatcher->{observers}} )
            {
            enqueue( $name, $observer );
            }
        }

    return $global_dispatcher->{queue}{$name};
    }

sub enqueue
    {
    my $name     = shift;
    my $observer = shift;

    my $observer_ref = refaddr( $observer );
    my $queue        = queue( $name );

#     printf "enqueuing: %s => %-7s %s\n", $observer_ref, "'$name'", join( ", ", map { sprintf( "[ %s => %s ]", $_, $queue->{$_} ) } sort keys %{$queue} );

    $DB::single = 1     if not $observer_ref;

    if( my $catcher = $observer->observer_for( $name ) )
        {
        $queue->{$observer_ref} = $catcher;
        }
    else
        {
        dequeue( $name, $observer_ref );
        }

#     printf "enqued: %s => %-7s %s\n", $observer_ref, "'$name'", join( ", ", map { sprintf( "[ %s => %s ]", $_, $queue->{$_} ) } sort keys %{$queue} );

    return;
    }

sub dequeue
    {
    my $name     = shift;
    my $observer = shift;

    my $queue        = queue( $name );
    my $observer_ref = ref( $observer ) ? refaddr( $observer ) : $observer;

    delete $queue->{$observer_ref};

#     printf "dequeued: %s <= %-7s %s\n", $observer_ref, "'$name'", join( ", ", map { sprintf( "[ %s => %s ]", $_, $queue->{$_} ) } sort keys %{$queue} );

    return;
    }

sub add_observer
    {
    my $observer = shift;

#     printf( "adding observer %s\n%s...\n", refaddr( $observer ), Dump( $global_dispatcher ) );

    # make sure we have a default, catch-all queue
    queue( '' );

    my $observer_ref = refaddr( $observer );
    weaken( $global_dispatcher->{observers}{$observer_ref} = $observer );

    foreach my $name ( keys %{$global_dispatcher->{queue}} )
        {
        enqueue( $name, $observer );
        }

#     printf( "added observer %s\n%s...\n", refaddr( $observer ), Dump( $global_dispatcher ) );

    return;
    }

sub remove_observer
    {
    my $observer = shift;

#     printf( "%s line %s removing observer %s\n%s...\n", (caller)[1,2], refaddr( $observer ), Dump( $global_dispatcher ) );

    foreach my $name ( keys %{$global_dispatcher->{queue}} )
        {
        dequeue( $name, $observer );
        }

    delete $global_dispatcher->{observers}{ refaddr( $observer ) };

#     printf( "removed observer %s\n%s...\n", refaddr( $observer ), Dump( $global_dispatcher ) );

    return;
    }

sub send
    {
    my $note = shift;

    my $name  = $note->name();
    my $queue = queue( $name );
    foreach my $observer_ref ( keys %{ $queue } )
        {
        if( not $global_dispatcher->{observers}{$observer_ref} )
            {
            # clean up an observer that was destroyed - can happen because we're using weak refs
            dequeue( $name, $observer_ref );
            next;
            }
        $queue->{$observer_ref}( $note );
        }

    return;
    }

1;

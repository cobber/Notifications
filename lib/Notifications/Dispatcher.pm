package Notifications::Dispatcher;

use strict;
use warnings;

use Scalar::Util qw( refaddr );

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
    if( not exists $self->{queue}{$name} )
        {
        $self->{queue}{$name} = [];
        foreach my $observer ( values %{$self->{observers}} )
            {
            my $catcher = $observer->observer_for( $name )  or next;
            push @{$self->{queue}{$name}}, [ $catcher, $observer ];
            }
        }
    return;
    }

sub add_observer
    {
    my $self     = shift;
    my $observer = shift;
    if( not $observer )
        {
        printf "GAH\n";
        my $i = 0;
        while( my @stack = (caller($i++))[0..2] )
            {
            printf "%s line %s\n", $stack[1], $stack[2];
            }
        }
    $self->{observers}{ refaddr( $observer ) } = $observer;
    foreach my $name ( keys %{$self->{queue}} )
        {
        my $catcher = $observer->observer_for( $name ) or next;
        push @{$self->{queue}{$name}}, [ $catcher, $observer ];
        }
    return;
    }

sub remove_observer
    {
    my $self     = shift;
    my $observer = shift;

    my $observer_ref = refaddr( $observer );
    foreach my $queue ( values %{$self->{queue}} )
        {
        @{$queue} = grep { defined( $_->[1] ) and not $_->[1] == $observer_ref } @{$queue};
        }
    delete $self->{observers}{ refaddr( $observer ) };
    return;
    }

sub send
    {
    my $self = shift;
    my $note = shift;
    my $name = $note->name();

    $self->prepare_queue( $name )  if not $self->{queue}{$name};

    foreach my $observer ( @{$self->{queue}{$name}} )
        {
        $observer->[0]->( $note );
        }

    return;
    }

1;

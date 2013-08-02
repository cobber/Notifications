package Notifications::Dispatcher;

use strict;
use warnings;

use Scalar::Util qw( refaddr );
use YAML;

my $global_dispatcher;

BEGIN {
    $global_dispatcher = bless {}, __PACKAGE__;
}

sub prepare_queue
    {
    my $name = shift;
    if( not exists $global_dispatcher->{queue}{$name} )
        {
        $global_dispatcher->{queue}{$name} = [];
        foreach my $observer ( values %{$global_dispatcher->{observers}} )
            {
            my $catcher = $observer->observer_for( $name )  or next;
            push @{$global_dispatcher->{queue}{$name}}, [ $catcher, $observer ];
            }
        }
    return;
    }

sub add_observer
    {
    my $observer = shift;
    $global_dispatcher->{observers}{ refaddr( $observer ) } = $observer;
    foreach my $name ( keys %{$global_dispatcher->{queue}} )
        {
        my $catcher = $observer->observer_for( $name ) or next;
        push @{$global_dispatcher->{queue}{$name}}, [ $catcher, $observer ];
        }
    return;
    }

sub remove_observer
    {
    my $observer = shift;
    my $observer_ref = refaddr( $observer );
    foreach my $queue ( values %{$global_dispatcher->{queue}} )
        {
        @{$queue} = grep { not $_->[1] == $observer_ref } @{$queue};
        }
    delete $global_dispatcher->{observers}{ refaddr( $observer ) };
    return;
    }

sub send
    {
    my $note = shift;
    my $name = $note->name();

    prepare_queue( $name )  if not $global_dispatcher->{queue}{$name};

    foreach my $observer ( @{$global_dispatcher->{queue}{$name}} )
        {
        $observer->[0]->( $note );
        }
#     my $stack = [ $notification->stack() ];
#     printf "dispatching:\n%s...\n", Dump( $notification,
#             {
#             name      => $notification->name()      // undef,
#             message   => $notification->message()   // undef,
#             timestamp => $notification->timestamp() // undef,
#             origin    => [ $notification->origin()  ],
#             data      => { $notification->data()    },
#             package   => $notification->package()   // undef,
#             stack     => [ $notification->stack() ],
#             },
#             );
    return;
    }

1;

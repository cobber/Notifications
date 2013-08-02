package Notifications::Observer;

use strict;
use warnings;

use Notifications::Dispatcher;

sub new   { return bless { catchers => {} }, shift; }
sub start { Notifications::Dispatcher::add_observer( shift ); }
sub stop  { Notifications::Dispatcher::remove_observer( shift ); }

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

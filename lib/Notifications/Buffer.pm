package Notifications::Buffer;

use strict;
use warnings;

use parent qw( Notifications::Observer );

sub new
    {
    my $class = shift;
    my $self  = bless {}, $class;

    $self->{notifications} = [];

    # start recording notifications immediately
    $self->start();

    return $self;
    }

sub accept_notification
    {
    my $self         = shift;
    my $notification = shift;

    push @{$self->{notifications}}, $notification;

    return;
    }

sub notifications
    {
    my $self = shift;

    return @{$self->{notifications}};
    }

## @fn      stop()
#  @brief   stop buffering and remove any captured notifications
#  @param   <none>
#  @return  <none>
sub stop
    {
    my $self = shift;

    $self->SUPER::stop();

    $self->{notifications} = [];

    return;
    }

1;

# TODO: Riehm [2011-02-15] write some documentation for this thing!

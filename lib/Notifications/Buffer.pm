package Notifications::Buffer;

use strict;
use warnings;

use parent qw( Notifications::Observer );

sub new
    {
    my $class = shift;
    my $self  = bless {}, $class;

    $self->{notifications} = [];

    return $self;
    }

sub accept_notification
    {
    my $self         = shift;
    my $notification = shift;
    push @{$self->{notifications}}, $notification;
    }

sub notifications
    {
    my $self = shift;
    return @{$self->{notifications}};
    }

sub stop
    {
    my $self = shift;
    $self->SUPER::stop();
    $self->{notifications} = [];
    }

1;

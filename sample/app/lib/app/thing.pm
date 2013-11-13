package app::thing;

use strict;
use warnings;

use app::notifications qw( chat );

sub new
    {
    my $class = shift;
    my $self  = bless { @_ }, $class;

    return $self;
    }

sub name
    {
    my $self = shift;
    return $self->{name};
    }

sub banter
    {
    my $self = shift;
    chat( "$self->{name}: ohhh I dunno.." );
    $self->chat( "$self->{name}: what do you reckon?" );
    return;
    }

sub exclaim
    {
    my $self = shift;
    $self->chat( "$self->{name}: brilliant!" );
    return;
    }

1;

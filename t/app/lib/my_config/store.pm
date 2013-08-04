package config::store;

use strict;
use warnings;

sub new
    {
    my $class = shift;
    my $param = { @_ };

    my $self = bless {}, $class;
    $self->{name}      = $param->{name} || ref( self ) =~ s/.*:://r;
    $self->{is_loaded} = 0;

    return $self;
    }

sub name
    {
    my $self = shift;
    return $self->{name};
    }

sub must_be_loaded
    {
    my $self = shift;
    $self->load() if not $self->{is_loaded};
    return;
    }

sub load {} # must be overridden by sub-classes

sub all_names
    {
    my $self = shift;
    return;
    }

1;

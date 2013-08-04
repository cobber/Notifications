package config::value;

use strict;
use warnings;

sub new
    {
    my $class = shift;
    my $param = { @_ };

    my $self = bless {}, $class;

    $self->{raw_values} = [];
    $self->{context_values} = {};

    return $self;
    }

1;

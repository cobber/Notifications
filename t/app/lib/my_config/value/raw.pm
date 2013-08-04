package config::value::raw;

use strict;
use warnings;

sub new
    {
    my $class = shift;
    my $param = { @_ };

    my $self = bless {}, $class;

    $self->{name}    = $param->{name};
    $self->{values}  = $param->{values}  || [];
    $self->{origin}  = $param->{origin};
    $self->{context} = $param->{context} || {};
    $self->{flags}   = $param->{flags}   || {};

    return $self;
    }

sub name    { my $self = shift; return $self->{name};         }
sub value   { my $self = shift; return ${$self->{values}}[0]; }
sub values  { my $self = shift; return @{$self->{values}};    }
sub origin  { my $self = shift; return $self->{origin};       }
sub context { my $self = shift; return $self->{context};      }
sub flags   { my $self = shift; return $self->{flags};        }

1;

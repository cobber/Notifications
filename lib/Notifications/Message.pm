package Notifications::Message;

use strict;
use warnings;

use Time::HiRes qw( gettimeofday );

sub new
    {
    my $class = shift;
    my $param = { @_ };

    my $self = bless {}, $class;

    $self->{name}      = $param->{name};
    $self->{text}      = $param->{text}      || '';
    $self->{data}      = $param->{data}      || {};
    $self->{origin}    = $param->{origin};
    $self->{sender}    = $param->{sender};
    $self->{timestamp} = $param->{timestamp} || [ gettimeofday() ];

    return $self;
    }

sub name      { my $self = shift; return $self->{name};      }
sub text      { my $self = shift; return $self->{text};      }
sub data      { my $self = shift; return $self->{data};      }
sub timestamp { my $self = shift; return $self->{timestamp}; }
sub package   { my $self = shift; return $self->{origin}[0]; }
sub sender    { my $self = shift; return $self->{sender};    }
sub file      { my $self = shift; return $self->{origin}[1]; }
sub line      { my $self = shift; return $self->{origin}[2]; }
sub function  { my $self = shift; return $self->{origin}[3]; }
sub stack
    {
    my $self = shift;

    my @stack = ();
    my $i = 1;
    while( my @caller = (caller($i++))[0..2] )
        {
        if( @stack or $caller[1] eq $self->{origin}[1] and $caller[2] == $self->{origin}[2] )
            {
            push @caller, (caller($i))[3];
            push @stack, \@caller;
            }
        }

    return @stack;
    }

1;

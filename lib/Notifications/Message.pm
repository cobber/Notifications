package Notifications::Message;

use strict;
use warnings;
use Time::HiRes qw( gettimeofday );

sub new
    {
    my $class = shift;
    my %param = @_;

    my $self = bless {}, $class;

    $self->{name}      = $param{name};
    $self->{message}   = $param{message}   || '';
    $self->{data}      = $param{data}      || {};
    $self->{origin}    = $param{origin};
    $self->{timestamp} = $param{timestamp} || [ gettimeofday() ];

#     printf ">>> %s %s\n", $self->name(), $self->message();

    return $self;
    }

sub DESTROY
    {
    my $self = shift;
#     printf "<<< %s %s\n", $self->name(), $self->message();
    return;
    }

sub name            { my $self = shift; return $self->{name};      }
sub message         { my $self = shift; return $self->{message};   }
sub timestamp       { my $self = shift; return $self->{timestamp}; }
sub package         { my $self = shift; return $self->{origin}[0]; }
sub file            { my $self = shift; return $self->{origin}[1]; }
sub line            { my $self = shift; return $self->{origin}[2]; }
sub function        { my $self = shift; return $self->{origin}[3]; }
sub data            { my $self = shift; return $self->{data};      }
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

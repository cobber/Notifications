package Notifications::Notification;

use strict;
use warnings;

sub new
    {
    my $class = shift;
    my %param = @_;

    my $self = bless {}, $class;

    $self->{event}            = $param{event};
    $self->{message}          = $param{message}          || '-';
    $self->{caller}           = $param{caller};
    $self->{timestamp}        = $param{timestamp}        || time();
    $self->{is_being_skipped} = $param{is_being_skipped} || 0;
    $self->{user_data}        = $param{user_data}        || {};

    return $self;
    }

sub skip
    {
    my $self = shift;
    $self->{is_being_skipped} = 1;
    return;
    }

sub event               { return shift->{'event'};            }
sub message             { return shift->{'message'};          }
sub timestamp           { return shift->{'timestamp'};        }
sub is_being_skipped    { return shift->{'is_being_skipped'}; }

sub caller
    {
    my $self = shift;
    return @{$self->{'caller'}};
    }

sub user_data
    {
    my $self = shift;
    return %{$self->{'user_data'}};
    }

1;

# TODO: Riehm [2011-02-15] write some documentation for this thing!

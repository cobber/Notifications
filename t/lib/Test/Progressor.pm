## @file    Progressor.pm
#  @brief   simple test module to use the 'progress' notification

package Test::Progressor;

use strict;
use warnings;

use Notifications qw( progress );

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    return $self;
}

sub foo {
    my $self = shift;

    $self->progress( "hi there" );

    return;
}

1;

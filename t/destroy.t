#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use Notifications::Observer;

my $thing = low_life->new()->start();

$thing = undef;

done_testing();

exit 0;

package low_life;

use parent qw( Notifications::Observer );

sub stop
    {
    my $self = shift;
    printf "farewell - cruel world\n";
    $self->SUPER::stop();
    return $self;
    }


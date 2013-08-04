#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use Notifications qw( test_message );
use Notifications::Observer;

my $count = 0;

my $observer = Notifications::Observer->new( '' => sub { $count++ } );

test_message();

is( $count, 1, 'observed message' );

$observer = undef;

test_message();

is( $count, 1, 'un-observed message' );

done_testing();
exit;

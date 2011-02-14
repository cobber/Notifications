## @file    buffering.t
#  @brief   test the buffering of notifications and the resenting of those
#           notifications to new observers

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok( 'Notifications' )         };
BEGIN { use_ok( 'Notifications::Buffer' ) };

# create an observer to catch the notifications which have already happened
# (Note: this is the same type of object used by Notifications)
my $logger = Notifications::Buffer->new();

# nothing has happened yet - that's fine
is( scalar( $logger->notifications() ), 0, 'observer should be initially empty' );

# do something that creates notifications
test_package::do_stuff();

is( scalar( $logger->notifications() ), 0, 'observer should still be empty before it starts observing notifications' );

# start observing notifications - should be pumped full with the notifications
# that have been buffered so far
$logger->start();

is( scalar( $logger->notifications() ), 8, 'expected number of buffered messages' );

# TODO: Riehm 2011-02-14 do a deep comparison of what was expected
# diag( Dump( $logger ) );

# TODO: Riehm 2011-02-14 check that global buffer is cleaned up when stopped

done_testing();
exit 0;

# generate some events to be generated BEFORE we create out observer
package test_package;   ## no critic (RequireFilenameMatchesPackage, ProhibitMultiplePackages)
use Notifications qw( -buffer this that the_other );

sub do_stuff
    {
    this( 'may be logged' );
    that( 'may be logged' );
    }

## @file    event_deactivation.t
#  @brief   test the deactivation of specific events and whether they appear
#           even if is_<event> is ignored

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok( 'Notifications', qw( trace debug info ) ) };
BEGIN { use_ok( 'Notifications::Buffer' ) };

# sorted for easier comparison
can_ok( 'main', qw( debug info is_debug is_info is_trace trace ) );
is_deeply( [ Notifications::known_events() ], [ qw( debug info trace ) ], 'expected events' );
is_deeply( [ Notifications::active_events() ], [ qw( debug info trace ) ], 'all events are active' );
is_deeply( [ Notifications::inactive_events() ], [ qw( ) ], 'no events should be inactive' );

# start tracking notifications
my $test_buffer = Notifications::Buffer->new();
$test_buffer->start();

is( is_trace(), 1, 'by default, debug messages are active' );
is( is_debug(), 1, 'by default, debug messages are active' );
is( is_info(),  1, 'by default, debug messages are active' );

trace( 'deactivating debug messages' );
Notifications::deactivate_event( 'debug' );

is( is_trace(), 1, 'by default, debug messages are active' );
is( is_debug(), 0, 'we should have turned off debug messages' );
is( is_info(),  1, 'by default, debug messages are active' );

trace( 'generating some messages...' );
debug( 'this should never happen' );
info( 'this should happen' );

# # TODO: Riehm 2011-02-14 do detailed testing of captured notifications
# diag( Dump( $test_buffer ) );

done_testing();
exit;

## @file    global_deactivation.t
#  @brief   test if all notifications can be deactivated and then the previously active
#           ones re-activated

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok( 'Notifications'         ) };
BEGIN { use_ok( 'Notifications::Buffer' ) };

my $test_buffer = Notifications::Buffer->new();

is_deeply( [ Notifications::known_events() ], [ qw( debug error info warning ) ], 'expected default known events' );

# check the initial state
{
    ok( is_debug(),   'debug should be active'   );
    ok( is_error(),   'error should be active'   );
    ok( is_info(),    'info should be active'    );
    ok( is_warning(), 'warning should be active' );

    # atcually create a message of each kind and make sure they appear in the buffer
    $test_buffer->start();
    debug(   'a debug message'   );
    error(   'a error message'   );
    info(    'a info message'    );
    warning( 'a warning message' );

    my $expected_notifications = {
        debug   => 1,
        error   => 1,
        info    => 1,
        warning => 1,
    };
    my $got_notifications = {};
    foreach my $notification ( $test_buffer->notifications() )
        {
        $got_notifications->{ $notification->event() } = 1;
        }
    $test_buffer->stop();   # clear the buffer

    is_deeply( $expected_notifications, $got_notifications, 'expect all default known events' );
}

# deactivate a single event
{
    Notifications::deactivate_event( 'debug' );

    ok( ! is_debug(),   'debug should be inactive'   );
    ok(   is_error(),   'error should be active'   );
    ok(   is_info(),    'info should be active'    );
    ok(   is_warning(), 'warning should be active' );

    # atcually create a message of each kind and make sure they appear in the buffer
    $test_buffer->start();
    debug(   'a debug message'   );
    error(   'a error message'   );
    info(    'a info message'    );
    warning( 'a warning message' );

    my $expected_notifications = {
        # debug   => 1, # should not even appear!
        error   => 1,
        info    => 1,
        warning => 1,
    };
    my $got_notifications = {};
    foreach my $notification ( $test_buffer->notifications() )
        {
        $got_notifications->{ $notification->event() } = 1;
        }
    $test_buffer->stop();   # clear the buffer

    is_deeply( $expected_notifications, $got_notifications, 'should get all but the debug message' );
}

# deactivate all events
{
    Notifications::deactivate_all_events();

    ok( ! is_debug(),   'debug should be inactive'   );
    ok( ! is_error(),   'error should be inactive'   );
    ok( ! is_info(),    'info should be inactive'    );
    ok( ! is_warning(), 'warning should be inactive' );

    # atcually create a message of each kind and make sure they appear in the buffer
    $test_buffer->start();
    debug(   'a debug message'   );
    error(   'a error message'   );
    info(    'a info message'    );
    warning( 'a warning message' );

    # all notifications should go missing
    my $expected_notifications = {
        # debug   => 1,
        # error   => 1,
        # info    => 1,
        # warning => 1,
    };
    my $got_notifications = {};
    foreach my $notification ( $test_buffer->notifications() )
        {
        $got_notifications->{ $notification->event() } = 1;
        }
    $test_buffer->stop();   # clear the buffer

    is_deeply( $expected_notifications, $got_notifications, 'not expecting any notifications here' );
}

# reactivate all events - previously deactivated events should stay deactivated
{
    Notifications::activate_all_events();

    ok( ! is_debug(),   'debug should still be inactive'   );
    ok(   is_error(),   'error should be active'   );
    ok(   is_info(),    'info should be active'    );
    ok(   is_warning(), 'warning should be active' );

    # atcually create a message of each kind and make sure they appear in the buffer
    $test_buffer->start();
    debug(   'a debug message'   );
    error(   'a error message'   );
    info(    'a info message'    );
    warning( 'a warning message' );

    # all notifications should go missing
    my $expected_notifications = {
        # debug   => 1,
        error   => 1,
        info    => 1,
        warning => 1,
    };
    my $got_notifications = {};
    foreach my $notification ( $test_buffer->notifications() )
        {
        $got_notifications->{ $notification->event() } = 1;
        }
    $test_buffer->stop();   # clear the buffer

    is_deeply( $expected_notifications, $got_notifications, 'previously activated event should have been re-activated' );
}

done_testing();
exit;

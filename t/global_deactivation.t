## @file    global_deactivation.t
#  @brief   test if all notifications can be deactivated and then the previously active
#           ones re-activated

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok( 'Notifications' ) };

# TODO: Riehm 2011-02-14 check that all events are active
Notifications::deactivate_event( 'debug' );
# TODO: Riehm 2011-02-14 check that debug is NOT active
Notifications::deactivate_all_events();
# TODO: Riehm 2011-02-14 check all events are inactive
Notifications::activate_all_events();
# TODO: Riehm 2011-02-14 check that debug is NOT active

done_testing();
exit;

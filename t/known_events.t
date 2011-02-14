## @file    known_events.t
#  @brief   check that known_events(), active_events() and inactive_events()
#           produce reasonable results

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok( 'Notifications' ) };

# TODO: Riehm 2011-02-14 specify a combination of tag and custom events in a
#                           variety of deeply nested modules and make sure they
#                           appear in known_events

done_testing();
exit;

## @file    syslog_functions.t
#  @brief   check that :syslog exports the correct syslog functions

use strict;
use warnings;

use Test::More;

BEGIN { use_ok( 'Notifications', qw( :syslog ) ) };

my @syslog_events = qw( debug info warning error alert critical emergency );
can_ok( 'main', @syslog_events );
can_ok( 'main', map { "is_$_"} @syslog_events );

done_testing();
exit;

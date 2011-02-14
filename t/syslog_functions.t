## @file    syslog_functions.t
#  @brief   check that :syslog exports the correct syslog functions

use strict;
use warnings;

use Test::More;

BEGIN { use_ok( 'Notifications', qw( :syslog ) ) };

# TODO: Riehm 2011-02-14 expect syslog functions

done_testing();
exit;

## @file    Custom.pm
#  @brief   simple test module to use the custome notifications

package Test::Custom;

use strict;
use warnings;

use Notifications qw( cookie_jar_full i_want_cookies cookie_jar_empty );

1;

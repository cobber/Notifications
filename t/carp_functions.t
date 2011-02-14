## @file    carp_functions.t
#  @breif   test the carp emulation (ie: correct caller information and die behaviour)

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok('Notifications', qw( :carp ) ) };

can_ok( 'main', qw( croak carp confess ) );

# TODO: Riehm 2011-02-14 actually try croaking, carping and confessing

done_testing();
exit;

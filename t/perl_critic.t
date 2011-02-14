## @file    perl_critic.t
#  @brief   make sure that perl critic doesn't have too many problems with our code

use strict;
use warnings;

use Test::More;
use YAML;

eval { require Test::Perl::Critic; }
    or plan( skip_all => 'Test::Perl::Critic required to criticise code' );

Test::Perl::Critic->import();
all_critic_ok();

done_testing();
exit;

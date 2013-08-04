## @file    notification_objects.t
## @brief   test the creation and operation of notification objects

use strict;
use warnings;

use Time::HiRes qw( gettimeofday );
use Test::More;
use Test::Differences;

BEGIN { use_ok( 'Notifications::Message' ) };

my $now  = [ gettimeofday() ];
my $data = {
            'shopping' => [ qw( eggs milk cookies ) ],
            };
my $test_notification = Notifications::Message->new(
    name      => 'test',
    message   => 'so what',
    timestamp => $now,
    origin    => [ 'test_package', 'test_file', 42, 'main' ], # all dummy data
    data      => $data,
    );

isa_ok( $test_notification,          'Notifications::Message', 'class check'     );
is( $test_notification->name(),                        'test', 'name check'      );
is( $test_notification->message(),                  'so what', 'message check'   );
is( $test_notification->package(),             'test_package', 'caller package'  );
is( $test_notification->file(),                   'test_file', 'caller file'     );
is( $test_notification->line(),                            42, 'caller line'     );
is( $test_notification->function(),                    'main', 'caller function' );
eq_or_diff( $test_notification->timestamp(),             $now, 'timestamp'       );
eq_or_diff( $test_notification->data(),                 $data, 'data'            );

done_testing();
exit;

## @file    notification_objects.t
## @brief   test the creation and operation of notification objects

use strict;
use warnings;

use Test::More;

BEGIN { use_ok( 'Notifications::Notification' ) };

my $now = time();
my $test_notification = Notifications::Notification->new(
    'event'     => 'test',
    'message'   => 'so what',
    'timestamp' => $now,
    'caller'    => [ 'test_package', 'test_file', 42, 'main' ], # all dummy data
    'user_data' => {
                    'shopping' => [ qw( eggs milk cookies ) ],
                    },
    );

isa_ok( $test_notification,  'Notifications::Notification', 'class check'            );
is( $test_notification->event(),                    'test', 'event check'            );
is( $test_notification->message(),               'so what', 'message check'          );
is( ($test_notification->caller())[0],      'test_package', 'caller package'         );
is( ($test_notification->caller())[1],         'test_file', 'caller file'            );
is( ($test_notification->caller())[2],                  42, 'caller line'            );
is( ($test_notification->caller())[3],              'main', 'caller function'        );
is( $test_notification->timestamp(),                  $now, 'timestamp'              );
is( $test_notification->is_being_skipped(),              0, 'do not skip by default' );

done_testing();
exit;

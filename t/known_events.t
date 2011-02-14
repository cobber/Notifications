## @file    known_events.t
#  @brief   check that known_events(), active_events() and inactive_events()
#           produce reasonable results

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok( 'Notifications' ) };

# get test modules from t/lib
use lib 't/lib';    

# keep track of what to expect so far
my $expected_events = {};


# check the notifications set up by default
{
    @{$expected_events}{qw( debug info warning error )} = ();
    my $known_events = { map { $_ => undef } Notifications::known_events() };
    is_deeply( $known_events, $expected_events, 'the usual candidates' );
}

# check the addition of a simple event type
{
    use_ok( 'Test::Progressor' );
    @{$expected_events}{qw( progress )} = ();   # add 'progress' to what we're expecting
    my $known_events = { map { $_ => undef } Notifications::known_events() };
    is_deeply( $known_events, $expected_events, 'progress should be in the mix' );
}


# check the addition of pre-defined event groups
{
    use_ok( 'Test::Syslogger'  );
    @{$expected_events}{qw( debug info notice warning error alert critical emergency )} = ();
    my $known_events = { map { $_ => undef } Notifications::known_events() };
    is_deeply( $known_events, $expected_events, 'syslog messages should have been added' );
}

# check the addition of custom events
{
    use_ok( 'Test::Custom'     );
    @{$expected_events}{qw( cookie_jar_full i_want_cookies cookie_jar_empty )} = ();
    my $known_events = { map { $_ => undef } Notifications::known_events() };
    is_deeply( $known_events, $expected_events, 'there is always an odd-ball' );
}

done_testing();
exit;

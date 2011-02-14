## @file    custom_functions.t
#  @brief   test the creation of custom event types

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok('Notifications') };

my @test_cases = (
        { 
            'test_line'   => __LINE__,
            'description' => 'a simple set of custom event types',
            'package'     => 'OneTwoThree',
            'use_args'    => [ qw( one two three ) ],
            'expect'      => {
                                'functions' => [ qw( one two three ) ],
                                },
        },
        { 
            'test_line'   => __LINE__,
            'description' => 'syslog with additional events',
            'package'     => 'SyslogSurprise',
            'use_args'    => [ qw( surprise :syslog progress ) ],
            'expect'      => {
                                'functions' => [ qw( debug info notice warning error critical alert emergency surprise progress ) ],
                                },
        },
    );

{
    foreach my $test_case ( @test_cases )
        {
        my $description  = sprintf( "Line %d: %s", $test_case->{test_line}, $test_case->{description} );
        my $test_package = sprintf( "Test::Notifications::%s", $test_case->{package} );
        my $eval_code    = sprintf( "package $test_package; use Notifications%s; 1;",
                                    $test_case->{use_args}
                                        ? " qw( @{$test_case->{use_args}} )"
                                        : ""
                                    );
        ok( eval $eval_code, $description );
        can_ok( $test_package, @{$test_case->{expect}{functions}} );
        }
}

done_testing();
exit;

## @file    export_permutations.t
#  @brief   test the creation of functions based on all possible permutations
#           of the input flags, ie: -prefix, -suffix

use strict;
use warnings;

use Test::More;

BEGIN { use_ok( 'Notifications' ) };

my @test_cases = (
        {
            'test_line'   => __LINE__,
            'description' => 'add a prefix to event functions - but keep original event names',
            'package'     => 'Prefix',
            'use_args'    => [ qw( -prefix wubble_ debug info warning error ) ],
            'expect'      => {
                                'functions' => [ qw(
                                        wubble_debug
                                        wubble_error
                                        wubble_info
                                        wubble_warning
                                        ) ],
                                },
        },
        {
            'test_line'   => __LINE__,
            'description' => 'add a suffix to event functions - but keep original event names',
            'package'     => 'Suffix',
            'use_args'    => [ qw( -suffix _wubble debug info warning error ) ],
            'expect'      => {
                                'functions' => [ qw(
                                        debug_wubble
                                        info_wubble
                                        warning_wubble
                                        error_wubble
                                        ) ],
                                },
        },
        {
            'test_line'     => __LINE__,
            'description'   => 'prefix and suffix',
            'package'       => 'PrefixSuffix',
            'use_args'      => [ qw( -suffix _check one two -prefix do_the_ error ) ],
            'expect'        => {
                                'functions' => [ qw(
                                        do_the_one_check
                                        do_the_two_check
                                        do_the_error_check
                                        ) ],
                                },
            'do_not_expect' => {
                                'functions' => [ qw( error info one two three ) ],
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
        ok( eval $eval_code, $description );   ## no critic (ProhibitStringyEval)
        can_ok( $test_package, @{$test_case->{expect}{functions}} );
        }
}

done_testing();
exit;

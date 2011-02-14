## @file    export_permutations.t
#  @brief   test the creation of functions based on all possible permutations
#           of the input flags, ie: -prefix, -suffix, -upper etc.

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok( 'Notifications' ) };

my @test_cases = (
        { 
            'test_line'   => __LINE__,
            'description' => 'add a prefix to event functions - but keep original event names',
            'package'     => 'Prefix',
            'use_args'    => [ qw( :default -prefix wubble_ ) ],
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
            'use_args'    => [ qw( -suffix _wubble :default ) ],
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
            'test_line'   => __LINE__,
            'description' => 'upper case function names - event names are always lower case',
            'package'     => 'Upper',
            'use_args'    => [ qw( :default -upper ) ],
            'expect'      => {
                                'functions' => [ qw( DEBUG INFO WARNING ERROR ) ],
                                },
        },
        { 
            'test_line'   => __LINE__,
            'description' => 'lower case function names',
            'package'     => 'Lower',
            'use_args'    => [ qw( ONE Two -lower thRee four ) ],
            'expect'      => {
                                'functions' => [ qw( one two three four ) ],
                                },
        },
        { 
            'test_line'   => __LINE__,
            'description' => 'upper case and with prefix',
            'package'     => 'UpperPrefix',
            'use_args'    => [ qw( -prefix foop_ one two three -upper ) ],
            'expect'      => {
                                'functions' => [ qw( FOOP_ONE FOOP_TWO FOOP_THREE ) ],
                                },
        },
        { 
            'test_line'   => __LINE__,
            'description' => 'upper case with suffix',
            'package'     => 'UpperSuffix',
            'use_args'    => [ qw( one two three -suffix _FOOP -upper ) ],
            'expect'      => {
                                'functions' => [ qw( ONE_FOOP TWO_FOOP THREE_FOOP ) ],
                                },
        },
        { 
            'test_line'     => __LINE__,
            'description'   => 'prefix and suffix',
            'package'       => 'PrefixSuffix',
            'use_args'      => [ qw( -suffix _check one two -prefix do_the_ error ) ],
            'expect'        => {
                                'functions' => [ qw( do_the_one_check do_the_two_check do_the_error_check ) ],
                                },
            'do_not_expect' => {
                                'functions' => [ qw( error info one two three ) ],
                                },
        },

    # TODO: Riehm 2011-02-14 check use of is_ and prefix etc (currently broken)
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

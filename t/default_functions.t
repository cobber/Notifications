## @file    default_functions.t
#  @brief   test the export of the default set of functions

use strict;
use warnings;

use Test::More;
use YAML;

BEGIN { use_ok('Notifications') };

my @test_cases = (
        { 
            'test_line'   => __LINE__,
            'description' => 'functions exported by default',
            'package'     => 'Default',
            'use_args'    => undef,
            'expect'      => {
                                'functions' => [ qw( debug info warning error ) ],
                                },
        },
        { 
            'test_line'   => __LINE__,
            'description' => 'functions exported explicitly by default',
            'package'     => 'ExplicitDefault',
            'use_args'    => [qw( :default )],
            'expect'      => {
                                'functions' => [ qw( debug info warning error ) ],
                                },
        },
    );

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

done_testing();
exit;

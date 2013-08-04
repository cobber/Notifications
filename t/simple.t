#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use Test::More;
pass( "hello" );

use Notifications qw( -prefix wanna_ hello fred exception warning debug error hello foo SCREAM );
use Notifications::Observer;
use YAML;

my $observer = Notifications::Observer->new();
$observer->set_callbacks(
                error => sub { count( shift, 'error'     ); },
                fred  => sub { count( shift, 'fred'      ); },
                foo   => sub { count( shift, 'foo'       ); },
                ''    => sub { count( shift, 'something' ); },
                );

# too lazy to stick around
Notifications::Observer->new();

my $errors = Notifications::Observer->new();
$errors->set_callbacks( error => sub { count( shift, 'wawawawaaaaaa' ) } );

my $is_paused = 0;
my $count = {};
sub count
    {
    return if $is_paused;
    my $note = shift;
    my $name = shift;
    $count->{$name}{$note->name()}++;
    return;
    }

my $logger = logger->new();

wanna_hello( 'blah' );
wanna_error( 'blah' );
# $is_paused = 1;
wanna_fred( 'blah' );
wanna_foo( 'blah' );
wanna_exception( 'blah' );
wanna_warning( 'blah' );
wanna_error( 'blah' );
wanna_scream( 'dammit' );

# remove unwanted observers
$observer->set_callbacks(           '' => undef, debug => undef );
$logger->{observer}->set_callbacks( '' => undef, debug => undef );

use Benchmark;

timethese( 100_000,
        {
        message_only      => sub { wanna_warning( "warning" ); },
        message_data      => sub { wanna_warning( "warning", foo => 'blah' ); },
        }
        );

# no observers - real quick!
timethese( 1_000_000,
        {
        message_only_void => sub { wanna_debug(   "debug" ); },
        message_data_void => sub { wanna_debug(   "debug", foo => 'blah' ); },
        },
        );

# see if this kills the observer - should only have a weak ref in dispatcher
$observer = undef;

wanna_scream( "one more time" );

printf "simple Stats:\n%s...\n", Dump( $count );
printf "logger stats:\n%s...\n", Dump( $logger );

done_testing();
exit;

package logger;

use Notifications::Observer;
use Class::Null;

sub new
    {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{is_paused} = 0;
    $self->{observer}  = Notifications::Observer->new(
#                                                         dispatcher => Class::Null->new(),
                                                        ''      => sub { $self->log( shift ); },    # will be removed for performance tests
                                                        'debug' => sub { $self->log( shift ); },
                                                    );
    $self->{stats}     = {};
    return $self;
    }

sub pause  { my $self = shift; $self->{is_paused} = 1; return $self; }
sub resume { my $self = shift; $self->{is_paused} = 0; return $self; }
sub stats  { my $self = shift; return $self->{stats}; }

sub log
    {
    my $self = shift;
    return     if $self->{is_paused};
    my $note = shift;
    $self->{stats}{$note->name()}++;
    push @{$self->{errors}}, $note   if $note->name() eq 'error';
    return;
    }


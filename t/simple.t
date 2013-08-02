#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use Notifications qw( -prefix wanna_ hello fred :syslog exception error hello foo SCREAM );
use Notifications::Observer;
use YAML;
use Scalar::Util qw( refaddr );

my $observer = Notifications::Observer->new();
$observer->observe_with(
                error => sub { count( shift, 'error'     ); },
                fred  => sub { count( shift, 'fred'      ); },
                foo   => sub { count( shift, 'foo'       ); },
                ''    => sub { count( shift, 'something' ); },
                );
$observer->start();

# too lazy to stick around
Notifications::Observer->new()->start();

my $errors = Notifications::Observer->new()->start();
$errors->observe_with( error => sub { count( shift, 'wawawawaaaaaa' ) } );

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

my $logger = logger->new()->start();

wanna_hello( 'blah' );
wanna_error( 'blah' );
# $is_paused = 1;
wanna_fred( 'blah' );
wanna_foo( 'blah' );
wanna_exception( 'blah' );
wanna_warning( 'blah' );
wanna_error( 'blah' );
wanna_scream( 'dammit' );

printf "killing %s\n", refaddr( $observer );
$observer->stop();

use Benchmark;

timethese( 100_000,
        {
        message_only => sub { wanna_hello( "blah" ); },
        message_data => sub { wanna_hello( "blah", foo => 'blah' ); },
        },
        );

printf "simple Stats:\n%s...\n", Dump( $count );
printf "logger stats:\n%s...\n", Dump( $logger );

# hello( "world" );
# fred( message => "world" );
# exception( "thing", name => 'blah' );
# error( message => "world", name => 'blah' );
# blah();
# bling->doing();
# 
# sub blah
#     {
#     fred( said => 'foo' );
#     }
# 
# exit 0;
# 
# package bling;
# 
# use Notifications qw( hello fred );
# 
# use Try::Tiny;
# 
# sub doing
#     {
#     try {
#         hello( "why?" );
#         fred( 'cus!' );
#         }
#     catch
#         {
#         hello( "dang" );
#         };
#     }

package logger;

use Notifications::Observer;

sub new
    {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{is_on}     = 0;
    $self->{is_paused} = 0;
    $self->{observer}  = Notifications::Observer->new();
    $self->{observer}->observe_with( '' => sub { $self->log( shift ); } );
    $self->{observer}->start();
    $self->{stats}     = {};
    return $self;
    }

sub start  { my $self = shift; $self->{is_on} = 1; return $self; }
sub stop   { my $self = shift; $self->{is_on} = 0; return $self; }
sub pause  { my $self = shift; $self->start(); $self->{is_paused} = 1; return $self; }
sub resume { my $self = shift; $self->start(); $self->{is_paused} = 0; return $self; }
sub stats  { my $self = shift; return $self->{stats}; }

sub log
    {
    my $self = shift;
    return unless $self->{is_on};
    return     if $self->{is_paused};
    my $note = shift;
    $self->{stats}{$note->name()}++;
    push @{$self->{errors}}, $note   if $note->name() eq 'error';
    return;
    }


#!/usr/local/bin/perl

use strict;
use warnings;

use Notifications qw( -message_class app::note );
use logger;
use cli;

# create a log file and catch all notifications
my $logger = logger->new();

my $cli = cli->new();

exit( $cli->run( @ARGV ) || 0 );

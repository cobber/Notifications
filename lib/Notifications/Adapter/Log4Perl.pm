package Notifications::Adapter::Log4Perl;

use strict;
use warnings;

use parent qw( Notifications::Observer );

use YAML;

# syslog -> log4perl level mappings
# important: each log4perl level must appear on both the left and right sides
my $log4perl_level = {
    'trace'     => 'trace', # not in syslog - but very common
    'debug'     => 'debug',
    'info'      => 'info',
    'notice'    => 'warn',
    'warning'   => 'warn',
    'warn'      => 'warn',
    'error'     => 'error',
    'fatal'     => 'fatal', # not in system - but very common
    'critical'  => 'fatal',
    'alert'     => 'fatal',
    'emergency' => 'fatal',
};

# TODO: Riehm [2011-02-14] allow the user to supply mappings
sub new
    {
    my $class = shift;
    my %param = @_;

    my $self = bless {}, $class;

    $self->{log} = $param{log}; # TODO: Riehm [2011-02-14] or die

    return $self;
    }

sub accept_notification
    {
    my $self         = shift;
    my $notification = shift;

    # ignore anything that Log::Dispatch or Log4Perl would not normally handle
    my $level = $log4perl_level->{ $notification->event() }     or return;

    no strict 'refs';   ## no critic (ProhibitNoStrict)
    $self->{log}->$level( $notification->message() );

    # TODO: Riehm [2011-02-14] log & die, log & warn
    }

sub log
    {
    my $self = shift;
    return $self->{log};
    }

1;

=head1 NAME

Notifications::Adapter::Log4Perl - send logging notifications to Log::Log4Perl

=head1 SYNOPSIS

    use Log::Log4Perl;
    use Notifications::Adapter::Log4Perl;

    my $log4perl_logger = Notifications::Adapter::Log4Perl->new(
                            log => Log::Log4Perl->get_logger( $category )
                            );

    $log4perl_logger->start();


=head1 DESCRIPTION

This is a simple adapter for sending logging notifications to Log4Perl.

Note that not all messages are sent to Log4Perl - only those which reflect
typical SysLog or Log4Perl logging levels.

=head2 Event Mappings

Incomming events are mapped according to the following structure:

    trace     => trace
    debug     => debug
    info      => info
    notice    => warn
    warning   => warn
    warn      => warn
    error     => error
    fatal     => fatal
    critical  => fatal
    alert     => fatal
    emergency => fatal

All other events are ignored!

=head1 SEE ALSO

Notifications,
Log::Log4Perl

=head1 AUTHOR

Stephen Riehm, E<lt>sriehm@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Stephen Riehm

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

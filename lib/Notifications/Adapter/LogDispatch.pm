package Notifications::Adapter::LogDispatch;

use strict;
use warnings;

use parent qw( Notifications::Observer );

use YAML;

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

    my $level = $notification->event();

    # ignore anything which Log::Dispatch would not normally log
    return if not $self->{log}->level_is_valid( $level ); 

    $self->{log}->log( 
            level   => $level,
            message => $notification->message(),
            );
    }

sub log
    {
    my $self = shift;
    return $self->{log};
    }

1;

=head1 NAME

Notifications::Adapter::LogDispatch - send logging notifications to Log::Dispatch

=head1 SYNOPSIS

    use Log::Dispatch;
    use Notifications::Adapter::LogDispatch;

    my $dispatch_logger = Notifications::Adapter::LogDispatch->new(
                            log => Log::Dispatch->new(),
                            );

    $dispatch_logger->start();


=head1 DESCRIPTION

This is a simple adapter for sending logging notifications to Log::Dispatch.

Note that not all messages are sent to Log::Dispatch - only those which reflect
typical SysLog or Log4Perl logging levels.

=head2 Event Mappings

Incomming events are mapped according to the following structure:

    trace     => debug      # Log::Dispatch doesn't recognise 'trace'
    debug     => debug
    info      => info
    notice    => notice
    warning   => warning
    warn      => warning    
    error     => error
    fatal     => critical   # Log::Dispatch doesn't recognise 'fatal'
    critical  => critical
    alert     => alert
    emergency => emergency

All other events are ignored!

=head1 SEE ALSO

Notifications,
Log::Dispatch

=head1 AUTHOR

Stephen Riehm, E<lt>sriehm@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Stephen Riehm

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

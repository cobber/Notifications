package Notifications;

use 5.010001;
use strict;
use warnings;

use Notifications::Notification;
use Carp qw( croak carp );

our $VERSION = '0.01';

my @observers   = ();        # ordered list of object references
my $buffer      = undef;     # special observer for catching unobserved notifications - off by default
my $can_send    = {
                    active_events => 1,     # global on/off switch
                    event         => {},    # on/off switch for individual events
                    };
my $tag         = {
                    'default'  => [qw( :typical )],
                    'typical'  => [qw( debug info warning error )],
                    'syslog'   => [qw( debug info notice warning error critical alert emergency )],
                    'log4perl' => [qw( trace debug info warn error fatal )],
                    'carp'     => [qw( croak carp confess )],    # TODO: Riehm 2011-02-14 install carp observer automatically?
                    # TODO: Riehm 2011-02-14 provide :admin to export add_observer, start/stop_all_events etc.?
                    };

## @fn      import( <class>, @param )
#  @brief   set up which functions should be visible to the caller
#  @detail  the caller defines which notifications they wish to use.
#           each notification can then be created by simply using it's name as a function
#  @param   -buffer         buffer notifications sent while there were no observers
#  @param   -nobuffer       do not buffer notifications sent while there were no observers (default)
#  @param   -prefix <text>  prefix for each notification function
#  @param   -suffix <text>  suffix for each notification function
#  @param   -upper          export all function names in UPPERCASE
#  @param   -upper          export all function names in lowercase
#  @param   :carp           provides the typical list of functions typically provided by Carp:
#                               croak, carp, confess
#  @param   :syslog         provides the typical list of syslog notifications:
#                               emergency, alert, critical, error, warning, notice, info and debug
#  @return  <none>
sub import
    {
    my $class   = shift;
    my @symbols = @_ ? @_ : qw( :default );
    my $caller  = caller;

    my $case    = '';
    my $prefix  = '';
    my $suffix  = '';
    my %export  = ();
    while( my $symbol = shift @symbols )
        {
        $prefix   = shift @symbols                              if $symbol =~ /^[-_]prefix/i;
        $suffix   = shift @symbols                              if $symbol =~ /^[-_]suffix/i;
        $case     = lc( $1 )                                    if $symbol =~ /^[-_](upper|lower)(case)?$/i;
        $buffer   = undef                                       if $symbol =~ /^[-_]no[-_]?buffer$/i;
        $buffer ||= Notifications::Buffer->new()                if $symbol =~ /^[-_]buffer$/i;
        $can_send->{active_events} = lc( $1 ) eq 'en' ? 1 : 0   if $symbol =~ /^[-_](en|dis)abled$/i;
        push( @symbols, @{$tag->{lc($1)}} )                     if $symbol =~ /^:(\w+)$/;
        next unless $symbol =~ /^\w+$/;
        $export{$symbol}++;
        }

    # start the buffer if one was requested
    $buffer->start()    if $buffer;

    no strict 'refs';   ## no critic (ProhibitNoStrict)
    foreach my $event ( map { lc } keys %export )
        {
        # create the notify function for this event
        my $notify_function = "${prefix}${event}${suffix}";
        $notify_function = uc( $notify_function ) if $case eq 'upper';
        $notify_function = lc( $notify_function ) if $case eq 'lower';
        notify(
                'event'   => 'setup',
                'message' => sprintf( "%s exporting %s::%s for event '%s'",
                                        ( (caller(0))[3] =~ /(.*)::/ ),
                                        $caller, $notify_function,
                                        $event
                                        ),
                );
        *{"$caller\::$notify_function"} = sub {
                                            $can_send->{active_events}
                                            and $can_send->{event}{$event}
                                            and notify(
                                                    'message'   => shift || '',
                                                    'event'     => $event,
                                                    'caller'    => [ (caller(0))[0..2], (caller(1))[3] || 'main' ],
                                                    'user_data' => { @_ },
                                                    );
                                            };

        # create a is_... function
        my $check_function = "${prefix}is_${event}${suffix}";
        $check_function = uc( $check_function ) if $case eq 'upper';
        $check_function = lc( $check_function ) if $case eq 'lower';
        notify(
                'event'   => 'setup',
                'message' => sprintf( "%s exporting %s::%s for event '%s'",
                                        ( (caller(0))[3] =~ /(.*)::/ ),
                                        $caller, $check_function,
                                        $event
                                        ),
                );
        *{"$caller\::$check_function"}   = sub { return( $can_send->{active_events} and $can_send->{event}{$event} ); };

        $can_send->{event}{$event} = 1;  # all events are 'on' by default
        }

    return;
    }

## @fn      add_observer( $observer )
#  @brief   add an observer to the list of observers
#  @detail  Observers are stored in a unique-stack.
#           Each observer will only be called once per notification, strating with the most recent observer.
#  @param   $observer   an object which responds to accept_notification()
#  @return  <none>
sub add_observer
    {
    my $class        = shift;
    my $new_observer = shift || croak sprintf "%s: please supply a reference to an observer", (caller(0))[3];

    unless( ref $new_observer )
        {
        carp sprintf( "%s: new observer needs to be an object with an accept_notification() method", (caller(0))[3] );
        return;
        }

    unless( $new_observer->can( 'accept_notification' ) )
        {
        carp sprintf( "%s: new observer doesn't have an 'accept_notification()' method - ignored", (caller(0))[3], ref( $new_observer ) );
        return;
        }

    # push the new observer to the front of the line and make sure it's unique
    @observers = ( $new_observer, grep { $_ ne $new_observer } @observers );

    # send any notifications that were collected while we were not being watched
    if( $buffer and $buffer ne $new_observer )
        {
        # TODO: Riehm 2011-02-14 only do this if the observer wasn't already registered?
        $new_observer->accept_notification( $_ ) foreach $buffer->notifications();
        }

    return;
    }

## @fn      remove_observer( $observer )
#  @brief   remove an obsever from the list of observing objects
#  @param   $observer   an object which responds to accept_notification()
#  @return  <none>
sub remove_observer
    {
    my $class        = shift;
    my $old_observer = shift || croak sprintf "%s: please supply a reference to an observer", (caller(0))[3];

    @observers = grep { $_ ne $old_observer } @observers;

    return;
    }

## @fn      notify( <message>, %params )
#  @brief   send a message to all observers - this should not be called directly!
#  @detail  a notification object will be created with the following information
#               message   =>    the first parameter supplied
#               event     =>    the name of the function used to send the notification - without package information
#               timestamp =>    the time that the message was first sent as seconds since the epoch
#               caller    =>    the first 4 elements of caller(0) - slightly adjusted to account
#                               for the anonymous sub used to generate notifications.
#               user_data =>    a hash of additional data provided by the caller
#           See Notifications::Notification for more details
#  @param   <message>   the first parameter is the message to be printed
#  @param   %params     all following parameters must be in name => value pairs for generic handling
#  @return  <none>
sub notify
    {
    my %param = @_;

    my $notification = Notifications::Notification->new(
        'message'   => $param{message},
        'event'     => $param{event},
        'caller'    => [ (caller(0))[0..3] ],
        'timestamp' => $param{timestamp} || time(),
        'user_data' => $param{user_data} || {},
        );

    # TODO: Riehm [2011-02-12] optimise for specific events
    foreach my $observer ( @observers )
        {
        last if $notification->is_being_skipped();
        $observer->accept_notification( $notification );
        }

    return;
    }

## @fn      start_buffer()
#  @brief   start buffering notifications until further notice
#  @warning this will become a memory leak if not turned off at some point!
#  @param   <none>
#  @return  <none>
sub start_buffer {
    $buffer ||= Notifications::Buffer->new();
    $buffer->start();
    return;
}

## @fn      stop_buffer()
#  @brief   stop buffering notifications. Any bufferred notifications will be lost!
#  @param   <none>
#  @return  <none>
sub stop_buffer {
    $buffer->stop() if $buffer;
    return;
}

## @fn      known_events()
#  @brief   provide the caller with an overview of all event types registered
#           by any modules included so far
#  @param   <none>
#  @return  a list of registered event names
sub known_events {
    return( sort( keys( %{$can_send->{event}} ) ) );
}

## @fn      activate_event( $event )
#  @brief   activate events of a specific type
#  @param   $event  the name of the event type to activate
#  @return  <none>
sub activate_event {
    my $event = shift;
    return unless $event;
    $can_send->{event}{$event} = 1;
    return;
}

## @fn      active_events()
#  @brief   indicate which events are currently active
#  @param   <none>
#  @return  a list active event names
sub active_events {
    return( sort ( grep { $can_send->{event}{$_} } keys( %{$can_send->{event}} ) ) );
}

## @fn      deactivate_event( $event )
#  @brief   deactivate events of a specific type
#  @param   $event  the name of the event type to deactivate
#  @return  <none>
sub deactivate_event {
    my $event = shift;
    return unless $event;
    $can_send->{event}{$event} = 0;
    return;
}

## @fn      inactive_events()
#  @brief   indicate which events are currently inactive
#  @param   <none>
#  @return  a list inactive event names
sub inactive_events {
    return( sort( grep { not $can_send->{event}{$_} } keys( %{$can_send->{event}} ) ) );
}

## @fn      activate_all_events()
#  @brief   turn of all event generation. No events will be produced or distributed after calling this method
#  @return  <none>
sub activate_all_events {
    $can_send->{active_events} = 1;
    return;
}

## @fn      deactivate_all_events( )
#  @brief   (re)-activate all events which were active before stop_all_events() was called
#  @return  <none>
sub deactivate_all_events {
    $can_send->{active_events} = 0;
    return;
}

1;
__END__
=head1 NAME

Notifications - provide customised functions for distributing notification messages

=head1 SYNOPSIS

  use Notifications qw( <configuration> );

=head1 DESCRIPTION

The intention of this module is to provide a light-weight notification center
to be used as a proxy for printf, Log::Dispatch, Log::Log4Perl etc.
In many ways this is the same as Log::Any, however, it can be used for any kind
of notification, not just logging!

Notifications allows you to specify what your module will report,
without binding it to a specific technique.

Later, the program using your module specifies which events to
use and how they should be handled, by providing one or more notification
observers which then handle the event message appropriately.

=head2 Sending Notifications

Any module can use notifications instead of printing to STDOUT, Carp'ing or
using more complex logging facilities such as Log::Dispatch or Log::Log4Perl.

To do this, the module author simply needs to specify which event types it
wants to produce, and then use the functions provided by Notifications to
produce those messages.

For example:

    package Do::What::I:Mean;

    use Notifications qw( error warning surprise );

    sub frobnicate
        {
        ...
        error( 'how did this happen?' )     unless $ok;
        ...
        surprise( "I didn't see that coming!", expected => 4, got => 5 );
        }

For the module author - this is all that needs to be done.

=head2 Catching Notifications

In order to catch the notifications produced by any included modules, the
application author needs to specify which notifications to use and how each
type should be processed.

Notifications provides a few adapters for typical cases, but to give you a
better idea of what's happening, we'll do it the long and hard way here:

    package MyMessageCatcher;
    use parent qw( Notifications::Observer );

    sub accept_notification
        {
        my $self         = shift;
        my $notification = shift;

        # only print high level stuff
        next unless $notification->event() =~ /^(info|error|warning)$/;

        printf( "%s %s: %s from %s\n",
            strftime( "%Y-%m-%d %H:%M:%S", $notification->timestamp() ),
            $notification->event(),
            $notification->message(),
            ($notification->caller())[3],
            );
        }

That's it! Now we just need a script that uses this information...

=head2 Putting it all together

So we've got some modules that produce notifications, we've got a custom
observer, now we just need to plug it all together and make it work.

Here's a simple script to do just that:

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Do::What::I::Mean;
    use MyMessageCatcher;

    my $logger = MyMessageCatcher->new();
    $logger->start();

    Do::What::I::Mean::frobnicate( with => [ this and that ] );

    exit 0;

At this point it should be noted that we could have used any combination of Log::Dispatch, Log::Log4Perl, some statistics module, progress counters

=head2 Controlling Notifications

Some notifications, especially optional ones which produce a lot of data,
should be disabled under most circumstances and only activated when really
required.

In addition to the simple event functions exported to each calling module,
Notifications also exports an 'is' function for each event and a matching
Notifications::start_<event> and Notifications::stop_<event>() control
functions for activating and deactiving individual events.

For example, a script might want to completely turn off tracing and debugging
unless explicitly requested, which might happen something like this:

    use Notifications;

    # stop_trace and
    Notifications::deactivate_event( 'trace' )   unless $cli{trace};   # all events are ON by default
    Notifications::deactivate_event( 'debug' )   unless $cli{debug};

    debug( Dump( $huge_thing ) )    if is_debug();

=head2 So what's going on here?

When you use Notifications, you define the 'events' that
your module can send. Notifications then exports a global function to your package for
each event.

In the example above, the functions: error() warning() and surprise() would
have been exported to the Do::What::I::Mean package.

Each function accepts a scalar message, optionally followed by a hash of
additional data which might be of use to a suitable recipient.

When sending a notification, a hash with the following structure is created and
sent to any observers who might be listening.

    $a_notification = {
        event     => '<eventname>',
        message   => '...',
        timestamp => ...,
        caller    => [ ... ],
        <additional data>
        };

=head1 INTENTIONS

Any module providing notifications should not be required to perform any setup
other than specifying which events it will produce. As a result, this module
deliberately displays the following characteristics:

=over

=item   Non-Object-Oriented

=item   No reliance on any other modules

=back

=head1 APPLICATIONS

Notifications can be used to distribute any kind of events within an
application. Some typical applications of this mechanism include:

=over

=item Logging

The :syslog tag can be used to automatically define functions for the events:
emergency, alert, critical, error, warning, notice, info and debug.

Sending these notifications, however, will not cause them to be sent to the
system's syslog logfile. That's the responsibility of an observer which accepts
the events mentioned above.

=item Configuration changes

Define an event such as 'config' and then notify the rest of the application
that it has changed.

=item Progress bars

See Notifications::ProgressBar for an example of how progress
notifications can be used to provide detailed progress bars without requiring
complex interaction setups.

=item "Soft"-exceptions

Notification observers are processed in reverse chronological order, ie: the
last observer to be added is the first one to be processed. Also, if an
observer dies while processing a notification, that notification will not be
passed on to any further observers.

These features allow you to create observers to capture notifications that
occur within a restricted scope for later analysis (e.g.: summarising the
warnings encountered during a complicated process).

If these notification-catching observers also throw an exception or die, then
the routine which created the observer can decide later if the process was
successfull 'enough' to continue or not. In this way, Notifications
works like a stack and can capture detailed error information without aborting
the current process (as an exception would).

Just don't forget to remove the observer before leaving the function!

=item Network Growls

Observers can, of course, also choose to send selected notifications to remote
servers, such as a desktop alert system (such as Growl) or even your pager or
email address (admin alerts for example).

=back

=head1 OPTIONS

The import options specify the names of the events to be generated and the
functions used to create them. In general, you can select from built-in event
lists or create your own, and then modify the function names so that they don't
collide with other functions in your package's namespace.

There are three types of option: tags, modifiers and event names.

Tags begin with a leading ':' and define a list of event names.

Modifiers begin with a leading '-' and specify how the generated function names
should be modified. Modifiers also apply to functions specified by tags!

Event names are plain words which are also subject to modification by the modifiers.

The options can be specified in any combination and order - the only
restrictions being that modifiers must be directly followed by their arguments,
if they need one, and it is not possible to un-select events (i.e.: it is not
possible to specify :syslog without the 'critical' event.)

=over

=item :default

Currently this is an alias for :typical

=item :typical

Defines the functions: debug, info, warning and error

=item :syslog

Defines the functions: debug, info, notice, warning, error, critical, alert and emergency

=item -prefix <...>

Adds the prefix to each generated function. The events, however, are not prefixed.
e.g.:

    use Notifications qw( -prefix my_ one two );
    my_one( ... );  # produces a 'one' event
    my_two( ... );  # produces a 'two' event

=item -suffix <...>

Analog to -prefix

=item -upper / -lower

Convert the function names to upper / lower case. Note: the event names are always produced in lowercase!

e.g.:

    use Notifications qw( -prefix my_ one two -upper );
    MY_ONE( ... );  # produces a 'one' event
    MY_TWO( ... );  # produces a 'two' event

=item -buffer / -nobuffer

It is possible that some events occur before your application has been able to
setup a suitable observer. For example, you might want to parse the
application's configuration files before determining where to write the
logfile. Normally, any events that happened during this time would be lost.
By specifying -buffer when you first use Notifications in your
application, any messages that are generated before the first observer has been
attached will be buffered and sent to the observer as soon as it has been
attached.

=item -enabled / -disabled

You may want to disable notifications in production code to improve performance.

=back

=head1 EXAMPLES

=head1 EXPORTS

Notifications exports four functions for each event type specified via the
import parameters.

=over

=item <event>( $message, %user_data )

Send an event notification.

=item is_<event>()

Indicate whether the particular type of event is currently of interest to the application.

For example:

    debug( Dump( $huge_object ) )   if is_debug();

=back

=head1 SEE ALSO

Notifications::Observer,
Notifications::Log4Perl,
Notifications::LogDispatch,
Notifications::Syslog,
Notifications::Growl,
Notifications::ProgressBar,
Log::Any,
Log::Dispatch,
Log::Log4Perl

=head1 AUTHOR

Stephen Riehm, E<lt>sriehm@cpan.orgE<gt>

=head1 THANKS

Robin Clarke for kicking my butt... er... motivating me to post a module on CPAN.

Andreas Hernitscheck for desperately need this module before it even got past alpha.

Ricardo SIGNES for the inspiration provided by Sub::Exporter.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Stephen Riehm

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

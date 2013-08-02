package Notifications;

use strict;
use warnings;

our $VERSION = '0.02';

# core modules only!
use Carp qw( croak );

# TODO: Riehm 2013-08-02 REMOVE ME after testing
use YAML;

use Notifications::Message;
use Notifications::Dispatcher;

our $senders     = {};
our $import_tags = {
                            'default'  => [qw( :typical )],
                            'typical'  => [qw( debug info warning error )],
                            'syslog'   => [qw( debug info notice warning error critical alert emergency )],
                            'log4perl' => [qw( trace debug info warn error fatal )],
                            'carp'     => [qw( croak carp confess )],    # TODO: Riehm 2011-02-14 install carp observer automatically?
                            };

## @fn      import( <class>, @param )
#  @brief   set up which functions should be visible to the caller
#  @detail  the caller defines which notifications they wish to send.
#           each notification can then be created by simply using it's name as
#           a function within the caller's package.
#  @param   -prefix <text>  prefix for each notification function
#  @param   -suffix <text>  suffix for each notification function
#  @param   :typical        provides a typical list of functions:
#                               debug, info, warning, error
#  @param   :carp           provides the list of functions typically provided by Carp:
#                               croak, carp, confess
#  @param   :syslog         provides functions expected by syslog:
#                               emergency, alert, critical, error, warning, notice, info and debug
#  @return  <none>
sub import
    {
    my $class   = shift;    # not used
    my @symbols = @_ ? @_ : qw( :default );
    my $caller  = caller;

    my $prefix          = '';
    my $suffix          = '';
    my %names_to_export = ();

    my $settings = {
        '-export_to_package' => sub { $caller = shift @symbols; },
        '-prefix'            => sub { $prefix = shift @symbols; },
        '-suffix'            => sub { $suffix = shift @symbols; },
    };

    # parse import parameters
    while( my $symbol = shift @symbols )
        {

        # simple settings
        if( $settings->{$symbol} )
            {
            &{$settings->{$symbol}};
            next;
            }

        # tags
        if( $symbol =~ /^:(\w+)$/ )
            {
            if( exists $import_tags->{ lc $1 } )
                {
                push @symbols, @{$import_tags->{lc $1 }};
                next;
                }
            else
                {
                croak( sprintf( "%s doesn't understand '%s'", $class, $symbol ) );
                }
            }

        # notification functions wanted by the caller
        if( $symbol =~ /^\w+$/ )
            {
            $names_to_export{ lc $symbol } = undef;    # only checking for 'exists'
            }
        else
            {
            croak( sprintf( "%s refusing to create function '%s()' - don't use non-alpha characters", $class, $symbol ) );
            }
        }

    # export the notification functions that the caller wants to use
    # - but only after having parsed the entire import list
    foreach my $name ( keys %names_to_export )
        {
        export_notification_function(
                name              => $name,
                export_to_package => $caller,
                prefix            => $prefix,
                suffix            => $suffix,
                );
        }

    return;
    }

## @fn      export_notification_function( %param )
#  @brief   create a notification sender in the calling package
#  @param   {name}              the name of the notification event to be created
#  @param   {export_to_package} the name of the package to get the new function
#  @param   {prefix}            functoin name prefix
#  @param   {suffix}            functoin name prefix
#  @param   {set_case_to}   convert to a specific upper/lower case?
#  @return  <none>
sub export_notification_function {
    my %param = @_;

    my $name            = $param{name};
    my $notify_function = sprintf( "%s::%s",
                                    $param{export_to_package},
                                    join( '', @param{qw( prefix name suffix )} ),
                                    );

    printf "exporting: $name as $notify_function() ...\n";

    {
        no strict 'refs';   ## no critic (ProhibitNoStrict)

        # create a function to actually send a new notification event
        # only create a sender for each type of notification once
        if( not defined $senders->{$name} )
            {
            printf "creating new sender for $name...\n";
            $senders->{$name} //= sub {
                                        my $message =   @_ % 2 ? shift : undef;
                                        my $param   =   { @_ };
                                        $message    //= delete $param->{message};
                                        Notifications::Dispatcher::send(
                                            Notifications::Message->new(
                                                name       => $name,
                                                message    => $message,
                                                data       => $param,
                                                origin  => [ (caller(0))[0..2], (caller(1))[3] ],
                                                )
                                            );
                                        };
            }
        *{$notify_function} = $senders->{$param{name}};
    }

    return;
}

1;
__END__
=head1 NAME

Notifications - provide customised functions for distributing notification messages

=head1 SYNOPSIS

=head2 For Module Authors...

    package Whizz::Bang;

    use Notifications qw( debug info surprise clear_cache );

    info( "Hi there" );

    is_debug()
        and debug( "Code quality check", criticisms => [ Perl::Critic->new()->critique( __FILE__ ) ] );

    clear_cache( 'need fresh sprockets', class => qr/\bsprocket\b/i );

    surprise( "Did you know", pigs => 'can fly' );

=head2 For Application Authors...

    use Notifications (
            '-map' => {
                detail   => 'debug',
                critical => 'error',
                fatal    => 'error',
                surprise => 'error',
                },
            );

    if( is_debug() )
        {
        Notifications::report_unmapped_types();
        }

    Notifications::Adapter::Log4Perl->new(); # create and start a log4perl logger

=head2 For Notification Handler Authors...

    package Notification::SurpriseHandler;

    sub new
        {
        my $self = bless {}, shift;

        Notifications::add_handler( $self );

        return $self;
        }

    sub filter_notification
        {
        my $self         = shift;
        my $notification = shift;
        return notfication_should_live( $notification ) ? 1 : 0;
        }

    sub accept_notification
        {
        my $self         = shift;
        my $notification = shift;

        print YAML::Dump( $notification );

        return;
        }

=head1 DESCRIPTION

The intention of this module is to provide a light-weight notification center
to allow module authors to provide useful feedback from their modules.
In many cases it might be a simple alternative to Log::Any - but notificatons
are not restricted in any way and can be used for much more than just simple
logging! See the Examples section below.

=head2 Basic Design Patterns

=over

=item Minimal Dependencies

This module is pure-perl and requires no non-core modules to install.

=item Ease-Of-Use

The interfaces provided by this module are intentionally simplistic but flexible.
Module authors need no setup beyond the 'use Notifications' declaration,
handlers need only implement the accept_notification() method and
applications need only create one handler. Use of this module should have a
minimal impact on the way you write your programs!

=item Singleton

There is only one notification handler - modules do not need to worry about
which handler to use for what reason - they just send notifications.

=item Observers

By default, notifications don't actually do anything. The perl script (as
opposed to the individual modules) must create one or more notification
handlers to catch notification events and do something useful with them.

=item Chain of Command

Event handlers are stored in a stack and each notification event is passed to
each handler in order. This makes it possible to filter, modify or capture
notifications much like exceptions, without changing the flow of logic.

=back

=head2 Sending Notifications

Any module can use notifications instead of printing to STDOUT, Carp'ing or
using more complex logging facilities such as Log::Dispatch or Log::Log4Perl.

To do this, the module author simply needs to specify which event types it
wants to produce, and then use the functions provided by Notifications to
produce those messages.

For example:

    package Do::What::I::Mean;

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
better idea of what's happening, we'll do it the long way here for
demonstration purposes:

    package MyMessageCatcher;
    use parent qw( Notifications::Handler );

    sub accept_notification
        {
        my $self         = shift;
        my $notification = shift;

        # only print high level stuff
        next unless $notification->event_name() =~ /^(info|error|warning)$/;

        printf( "%s %s: %s from %s\n",
            strftime( "%Y-%m-%d %H:%M:%S", $notification->timestamp() ),
            $notification->event_name(),
            $notification->message(),
            ($notification->caller())[3],
            );
        }

That's it! Now we just need a script that uses this information...

=head2 Putting it all together

So we've got some modules that produce notifications, we've got a custom
handler, now we just need to plug it all together and make it work.

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

In addition to the simple notification functions exported to each calling module,
Notifications also exports an 'is' function for each notification event.

Specific Notification events may be suppressed by using Notifications::deactivate_event_with_name() and activated again with Notifications::activate_event_with_name()

For example, a script might want to completely turn off tracing and debugging
unless explicitly requested, which might happen something like this:

    use Notifications;

    # stop_trace and
    Notifications::deactivate_event_with_name( 'trace' )   unless $cli{trace};   # all events are ON by default
    Notifications::deactivate_event_with_name( 'debug' )   unless $cli{debug};

    debug( Dump( $huge_thing ) )    if is_debug();

=head2 So what's going on here?

When you use Notifications, you define the 'events' that
your module can send. Notifications then exports a global function to your package for
each notification event.

In the example above, the functions: error() warning() and surprise() would
have been exported to the Do::What::I::Mean package.

Each function accepts a scalar message, optionally followed by a hash of
additional data which might be of use to a suitable recipient.

When sending a notification, a Notifications::Notification object is created
with the following structure and sent to any handlers who might be listening.

    $a_notification = {
        event_name     => '<eventname>',
        message   => '...',
        timestamp => ...,
        caller    => [ ... ],
        user_data => { <additional data> },
        };

See Notifications::Notification for more details.

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
system's syslog logfile. That's the responsibility of a handler which accepts
the events mentioned above.

=item Configuration changes

Define a notification event such as 'config' and then notify the rest of the application
whenever changes to the conifguration occur.

=item Progress bars

See Notifications::ProgressBar for an example of how progress
notifications can be used to provide detailed progress bars without requiring
complex interaction setups.

=item "Soft"-exceptions

Notification handlers are processed in reverse chronological order, ie: the
last handler to be added is the first one to be processed. Also, if a
handler dies while processing a notification, that notification will not be
passed on to any further handlers.

These features allow you to create handlers to capture notifications that
occur within a restricted scope for later analysis (e.g.: summarising the
warnings encountered during a complicated process).

If these notification-catching handlers also throw an exception or die, then
the routine which created the handler can decide later if the process was
successfull 'enough' to continue or not. In this way, Notifications
works like a stack and can capture detailed error information without aborting
the current process (as an exception would).

Just don't forget to remove the handler before leaving the function!

=item Network Growls

Handlers can, of course, also choose to send selected notifications to remote
servers, such as a desktop alert system (such as Growl) or even your pager or
email address (admin alerts for example).

=back

=head1 OPTIONS

The import options specify the names of the events to be generated and the
functions used to create them. In general, you can select from built-in event
lists or create your own, and then modify the function names so that they don't
collide with other functions in your package's namespace.

There are three types of option: tags, modifiers and event names.

Tags begin with a leading ':' and define a list of event names. For example: :syslog

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
    my_one( ... );  # produces a 'one' notification event
    my_two( ... );  # produces a 'two' notification event

=item -suffix <...>

Analog to -prefix

=item -upper / -lower

Convert the function names to upper / lower case.
Note: by default the notification functions are always produced in lowercase!

e.g.:

    use Notifications qw( -prefix my_ one two -upper );
    MY_ONE( ... );  # produces a 'one' notification event
    MY_TWO( ... );  # produces a 'two' notification event

=item -enabled / -disabled

You may want to disable notifications in production code to improve performance.

=back

=head1 EXAMPLES

=head1 EXPORTS

Notifications exports two functions for each notification event specified via the
import parameters.

=over

=item <event_name>( $message, %user_data )

Send an event notification.

=item is_<event_name>()

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

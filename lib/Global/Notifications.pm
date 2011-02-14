package Global::Notifications;

use 5.010001;
use strict;
use warnings;
use Carp qw( croak carp );

our $VERSION = '0.01';

my $enabled   = 1;
my @observers = (); # ordered list of object references
my $buffer    = []; # for catching unobserved notifications
my %tag       = (
                'default' => [qw( :typical )],
                'typical' => [qw( debug info warning error )],
                'syslog'  => [qw( debug info notice warning error critical alert emergency )],
                'extreme' => [qw( :syslog trace )],
                );

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
        $prefix   = shift @symbols              if $symbol =~ /^[-_]prefix/i;
        $suffix   = shift @symbols              if $symbol =~ /^[-_]suffix/i;
        $case     = lc( $1 )                    if $symbol =~ /^[-_](upper|lower)(case)?$/i;
        $buffer   = undef                       if $symbol =~ /^[-_]nobuffer$/i;
        $buffer ||= []                          if $symbol =~ /^[-_]buffer$/i;
        $enabled  = lc( $1 ) eq 'en' ? 1 : 0    if $symbol =~ /^[-_](en|dis)abled$/i;
        push( @symbols, @{$tag{lc($1)}} )       if $symbol =~ /^:(\w+)$/;
        next unless $symbol =~ /^\w+$/;
        $export{$symbol}++;
        }

    no strict 'refs';   ## no critic (Stricture)
    foreach my $event ( map { lc } keys %export )
        {
        my $invocation = "$prefix$event$suffix";
        $invocation = uc( $invocation ) if $case eq 'upper';
        $invocation = lc( $invocation ) if $case eq 'lower';
        notify(
                'event'   => 'setup',
                'message' => sprintf( "%s exporting %s::%s for event '%s'",
                                        ( (caller(0))[3] =~ /(.*)::/ ),
                                        $caller, $invocation,
                                        $event
                                        ),
                );
        *{"$caller\::$invocation"} = sub {
                                            $enabled and notify(
                                                    @_,
                                                    'event'  => $event,
                                                    'caller' => [ (caller(0))[0..2], (caller(1))[3] || 'main' ],
                                                    );
                                            };
        }

    return;
    }

## @fn      add_observer( $observer )
#  @brief   add an observer to the list of observers
#  @detail  observers are stored in chronological order of addition
#           each observer will only be called once per notification
#  @param   $observer   an object which responds to accept_notification()
#  @return  <none>
sub add_observer
    {
    my $class        = shift;
    my $new_observer = shift || croak sprintf "%s: please supply a reference to an observer", (caller(0))[3];

    unless( $new_observer->can( 'accept_notification' ) )
        {
        carp sprintf( "%s: new observer doesn't have an 'accept_notification()' method - ignored", (caller(0))[3], ref( $new_observer ) );
        return;
        }

    @observers = ( $new_observer, grep { $_ ne $new_observer } @observers );

    # send any notifications that were collected while we were not being watched
    if( $buffer and @{$buffer} )
        {
        notify( %$_ ) foreach @{$buffer};
        $buffer = [];
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
#  @detail  the message will be turned into a notification hash with the following keys:
#               message   =>    the first parameter supplied
#               event     =>    the name of the function used to send the notification - without package information
#               timestamp =>    the time that the message was first sent as seconds since the epoch
#  @param   <message>   the first parameter is the message to be printed
#  @param   %params     all following parameters must be in name => value pairs for generic handling
#  @return  <none>
sub notify
    {
    my $notification = { message => ( @_ % 2 ) ? shift || '-' : '-', @_ };

    $notification->{event}      ||= 'notification';
    $notification->{timestamp}  ||= time();
    $notification->{caller}     ||= [ (caller(0))[0..3] ];

    if( @observers )
        {
        # TODO: Riehm [2011-02-12] optimise for specific events
        eval { $_->accept_notification( $notification ) foreach @observers; };
        if( my $exception = $@ )
            {
            unless( ref( $exception ) and ref( $exception ) =~ /skip.*notification/i
                    or $exception =~ /skip.*notification/i
                  )
                {
                if( ref( $exception ) and $exception->can( 'rethrow' ) )
                    {
                    $exception->rethrow();
                    }
                else
                    {
                    croak( $exception );
                    }
                }
            }
        }
    else
        {
        push @{$buffer}, $notification  if $buffer;
        }

    return;
    }

1;
__END__
=head1 NAME

Global::Notifications - provide customised functions for distributing notification messages

=head1 SYNOPSIS

  use Global::Notifications qw( <configuration> );

=head1 DESCRIPTION

The intention of this module is to provide a light-weight notification center
to be used as a proxy for printf, Log::Dispatch, Log::Log4Perl etc.

Global::Notifications allows you to specify what your module will report,
without binding it to a specific technique.

Later, the program using your module specifies which events to
use and how they should be handled, by providing one or more notification
observers which then handle the event message appropriately.

A simple example:

    package Do::What::I:Mean;

    use Global::Notifications qw( error warning surprise );

    sub frobnicate
        {
        ...
        error( 'how did this happen?' )     unless $ok;
        ...
        surprise( "I didn't see that coming!", expected => 4, got => 5 );
        }

Having done that, you shouldn't notice any difference to the way your module
works, and you wont see any output (yet) either!

=head2 So what's going on here?

When you use Global::Notifications, you define the 'events' that
your module can send. Global::Notifications then exports a global function to your package for
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

Global::Notifications can be used to distribute any kind of events within an
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

See Global::Notifications::ProgressBar for an example of how progress
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
successfull 'enough' to continue or not. In this way, Global::Notifications
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

    use Global::Notifications qw( -prefix my_ one two );
    my_one( ... );  # produces a 'one' event
    my_two( ... );  # produces a 'two' event

=item -suffix <...>

Analog to -prefix

=item -upper / -lower

Convert the function names to upper / lower case. Note: the event names are always produced in lowercase!

e.g.:

    use Global::Notifications qw( -prefix my_ one two -upper );
    MY_ONE( ... );  # produces a 'one' event
    MY_TWO( ... );  # produces a 'two' event

=item -buffer / -nobuffer

It is possible that some events occur before your application has been able to
setup a suitable observer. For example, you might want to parse the
application's configuration files before determining where to write the
logfile. Normally, any events that happened during this time would be lost.
By specifying -buffer when you first use Global::Notifications in your
application, any messages that are generated before the first observer has been
attached will be buffered and sent to the observer as soon as it has been
attached.

=item -enabled / -disabled

You may want to disable notifications in production code to improve performance.

=back

=head1 EXAMPLES

=head1 EXPORTS

Global::Notifications only exports the event functions that your module
specifies. Use prefixes or suffixes to avoid naming conflicts.

=head1 SEE ALSO

Global::Notifications::Observer,
Global::Notifications::Log4Perl,
Global::Notifications::LogDispatch,
Global::Notifications::Syslog,
Global::Notifications::Growl,
Global::Notifications::ProgressBar,
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

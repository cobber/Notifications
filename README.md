NOTIFICATIONS
=============

The Notifications module is a general purpose system for sending and receiving
messages within an application.

This kind of message handling is typically known as the *Observer* or
*Publisher / Subscriber* pattern and is well suited for:

    - logging
    - triggering actions without prior knowledge
    - event sequencing
    - progress monitoring
    - output handling
    - etc.

WHY *NOT* Log::Any, Log::Log4Perl, Log::Dispatch etc.?
------------------------------------------------------

The Log::* modules all handle logging, but they ONLY handle logging.
Notifications are a more generic concept, there are no levels and no
restrictions to the kinds of messages which can be sent.

The intention of Notifications is that they can be used by any module for any
purpose. The ability to carry additional data also makes it possible for objects
to refer to themselves (providing callbacks) or structured, additional
information which can be used directly by the receiver.

Using Notifications in modules
------------------------------

Any module which uses the Notifications module automatically gets a set of
functions defined in its namespace for sending notification objects.

For example:

```perl
    package MyModule;

    use Notifications (
                        -prefix => 'send_',
                        qw( clear_cache note progress start finish )
                        );

    sub do_stuff {
        send_progress( "doing stuff", step => 0, of => 4 );
        send_start( "I just started" );
        send_progress( step => 1, of => 4 );
        send_clear_cache();
        send_progress( step => 2, of => 4 );
        send_note( "making a new widget", widget => $widget );
        send_progress( step => 3, of => 4 );
        send_finish( "all done" );
        send_progress( step => 4, of => 4 );
    }

    1;
```

In this example, functions for sending messages with the name *clear_cache*,
*note*, *start* & *finish* are created in the module*s namespace with an
optional *send_* prefix.
Thus, the `send_start()` function sends a *start* message, `send_note()` sends
a *note* message and so on.

The example above shows all of the different ways that the notification sending
functions can be used:

    1.  without any parameters
    2.  with a message text
    3.  with a set of key/value pairs
    4.  with a message text and additional key/value pairs

In each case, a **Notifications::Message** object is created and sent to all
registered observers (see below) for further processing.

Receiving Notifications
-----------------------

Any module can receive these messages by creating a **Notifications::Observer**
object and specifying which messages are of interest and how they are to
be processed.

```perl
    #!/usr/bin/perl

    use Notifications::Observer;
    use MyModule;

    open( my $logfile_fh, '>', 'logfile.out' )    or die;
    my $logger = Notifications::Observer->new( 'debug' => \&write_log );

    sub write_log
        {
        my $message = shift;
        printf $logfile_fh "%s: %s\n", uc( $message->name() ), $message->text();
        }

    # start doing stuff with MyModule ...
```

In this example, only the debug messages will be logged, all other
notificiations will be completely ignored by the system.

See the Notifications documentation for more details.

INSTALLATION
============

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

Dependencies
------------

None, that's why I wrote this module :-)

Actually, Notifications does use `Carp`, `Time::HiRes` and `Scalar::Util`,
however, all of these have been in perl's core-modules list since v5.7.3

COPYRIGHT AND LICENCE
=====================

Put the correct copyright and licence information here.

Copyright (C) 2011 by Stephen Riehm

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

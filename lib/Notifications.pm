package Notifications;

use strict;
use warnings;

our $VERSION = '0.03';

# core modules only!
use Carp qw( croak );

use Notifications::Dispatcher;

our $dispatcher    = Notifications::Dispatcher->new();
our $message_class = 'Notifications::Message';
our $senders       = {};    # <message-name> => <code-ref>

## @fn      import( @param )
#  @brief   set up subs for sending notifications
#  @detail  The caller defines which notifications they wish to send.
#           each notification can then be created and sent by calling a sub
#           with the same name as the notification within the caller's package.
#  @param   -dispatcher         <object>    specify a non-standard dispatcher to use instead of the default: Notifications::Dispatcher object.
#                                           this object must have a ->send( $message ) method.
#  @param   -message_class      <text>      create messages by using this class instead of the default Notifications::Message.
#                                           should only be set once per application!
#  @param   -export_to_package  <text>      create methods for a specific package (default: the caller's package)
#  @param   -prefix             <text>      prefix for each notification sub
#  @param   -suffix             <text>      suffix for each notification sub
#  @return  <none>
sub import
    {
    my $class   = shift;    # place-holder - not used
    my @param = @_;         # list of notification types to be set up
    my $caller  = caller;   # package of caller

    my $prefix          = '';
    my $suffix          = '';
    my %names_to_export = ();

    my $parser_for = {
        '-dispatcher'        => sub { $dispatcher    = shift @param; },
        '-message_class'     => sub { $message_class = shift @param; },
        '-export_to_package' => sub { $caller        = shift @param; },
        '-prefix'            => sub { $prefix        = shift @param; },
        '-suffix'            => sub { $suffix        = shift @param; },
    };

    # parse import parameters
    while( my $arg = shift @param )
        {

        # extract parameters with special meaning
        if( $parser_for->{$arg} )
            {
            &{$parser_for->{$arg}}();
            next;
            }

        # notification functions wanted by the caller
        if( $arg =~ /^\w+$/ )
            {
            $names_to_export{ lc $arg } = undef;    # only check for 'exists'
            }
        else
            {
            croak( sprintf( "%s refusing to create function '%s()' - don't use non-alpha characters", $class, $arg ) );
            }
        }

    # nasty hack to cater for require not being nice about modules / class name mappings
    my $message_module = $message_class . '.pm';
    $message_module =~ s!::!/!g;
    eval { require $message_module; };
    croak( "Could not load '$message_class' module: $@\n" ) if $@;

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
#  @param   {prefix}            function name prefix
#  @param   {suffix}            function name prefix
#  @return  <none>
sub export_notification_function {
    my $param = { @_ };

    my $name            = $param->{name};
    my $notify_function = sprintf( "%s::%s",
                                    $param->{export_to_package},
                                    join( '', @{$param}{qw( prefix name suffix )} ),
                                    );

    # create a sub to actually send a new notification event
    # only create one sender for each type of notification
    $senders->{$name} //= sub {
                                return if not $dispatcher->has_observers_for( $name );      # short-cut if there are no observers for this name - speed x 10!
                                my $sender     = ref($_[0]) ? shift : undef;
                                my $text       = @_ % 2     ? shift : undef;
                                my $send_param = { @_ };
                                $text //= delete $send_param->{text};
                                $dispatcher->send(
                                    $message_class->new(
                                        sender  => $sender,                                 # the object which created this notification
                                        name    => $name,                                   # closure variable
                                        text    => $text,                                   # from caller
                                        data    => $send_param,                             # from caller
                                        origin  => [ (caller(0))[0..2], $notify_function ], # give anon-sub a proper name
                                        )
                                    );
                                };

    {
        no strict 'refs';   ## no critic (ProhibitNoStrict)
        *{$notify_function} = $senders->{$name};
    }

    return;
}

1;

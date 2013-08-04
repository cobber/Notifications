package Notifications;

use strict;
use warnings;

our $VERSION = '0.02';

# core modules only!
use Carp qw( croak );

use Notifications::Dispatcher;
use Notifications::Message;

our $dispatcher  = Notifications::Dispatcher->new();
our $note_class  = 'Notifications::Message';
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
        '-dispatcher'        => sub { $dispatcher = shift @symbols; },
        '-note_class'        => sub { $note_class = shift @symbols; },
        '-export_to_package' => sub { $caller     = shift @symbols; },
        '-prefix'            => sub { $prefix     = shift @symbols; },
        '-suffix'            => sub { $suffix     = shift @symbols; },
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

    eval "require $note_class";
    die "oops: $@\n" if $@;

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
        # create a function to actually send a new notification event
        # only create a sender for each type of notification once
        if( not defined $senders->{$name} )
            {
            printf "creating new sender for $name...\n";
            $senders->{$name} //= sub {
                                        return if not $dispatcher->has_observers_for( $name );
                                        my $message =   @_ % 2 ? shift : undef;
                                        my $param   =   { @_ };
                                        $message    //= delete $param->{message};
                                        $dispatcher->send(
                                            $note_class->new(
                                                name       => $name,
                                                message    => $message,
                                                data       => $param,
                                                origin     => [ (caller(0))[0..2], $notify_function ],
                                                )
                                            );
                                        };
            }

        no strict 'refs';   ## no critic (ProhibitNoStrict)
        *{$notify_function} = $senders->{$param{name}};
    }

    return;
}

1;

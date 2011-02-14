package Notifications::Progress;

use strict;
use warnings;

use parent qw( Notifications::Observer );

use YAML;
use POSIX qw( strftime );

sub new
    {
    my $class = shift;
    my %param = @_;

    my $self = bless Notifications::Observer->new(), $class;

    $self->{start_time}         = time();
    $self->{current_step}       = 0;
    $self->{max_steps}          = 0;
    $self->{show_bar}           = 1;
    $self->{show_messages}      = 1;
    $self->{show_percent}       = 1;
    $self->{show_duration}      = 1;
    $self->{show_steps}         = 1;
    $self->{bar_width}          = 40;
    $self->{last_message_length} = 0;

    return $self;
    }

# @param {event}             must be 'progress'
# @param {expect}           increase the maximum number of expected steps
# @param {step}             set the current step number
# @param {message}          the message to print
# @param {show_bar}          turn on / off the progress bar
# @param {show_duration}     turn on / off the duration display
# @param {show_steps}        turn on / off the (n of m) display
# @param {show_messages}     turn on / off display of the messages
sub accept_notification
    {
    my $self         = shift;
    my $notification = shift;

#     return unless $notification->{event} =~ /progress/;
    return unless $notification->{event} eq 'progress';

    local $| = 1;
    $self->{bar_width}      = $notification->{bar_width}        if $notification->{bar_width} || 0 >= 1;
    $self->{show_bar}       = $notification->{show_bar}         if exists $notification->{show_bar};
    $self->{show_duration}  = $notification->{show_duration}    if exists $notification->{show_duration};
    $self->{show_steps}     = $notification->{show_steps}       if exists $notification->{show_steps};
    $self->{show_messages}  = $notification->{show_messages}    if exists $notification->{show_messages};
    $self->{max_steps}     += $notification->{expect}           if $notification->{expect};
    $self->{current_step}  += 1                                 if $self->{max_steps} and not $notification->{finished};
    $self->{current_step}   = $notification->{step}             if exists $notification->{step};
    $self->{max_steps}      = $self->{current_step}             if $notification->{finished};
    $self->{max_steps}      = $self->{current_step}             if $self->{current_step} > $self->{max_steps};

    my @output   = ();

    if( $self->{show_messages} )
        {
        push @output, strftime( "%H:%M:%S", localtime( $notification->{timestamp} ) );
        }

    if( $self->{show_bar} and $self->{max_steps} ) 
        {
        my $progress = int( $self->{current_step} / $self->{max_steps} * $self->{bar_width} );
        push @output, sprintf( "|%s%s|",
                                '#' x (                      $progress ),
                                '-' x ( $self->{bar_width} - $progress ),
                                );
        }

    if( $self->{show_percent} and $self->{max_steps} )
        {
        push @output, sprintf( "%3d%%", int( $self->{current_step} / $self->{max_steps} * 100 ) );
        }

    if( $self->{show_steps} and $self->{max_steps} )
        {
        my $steps_width = length( "$self->{max_steps}" );
        push @output, sprintf( "(%*d of %*d)",
                                $steps_width, $self->{current_step},
                                $steps_width, $self->{max_steps},
                                );
        }

    if( $self->{show_duration} )
        {
        push @output, sprintf( "(%d seconds)", time() - $self->{start_time} );
        }

    if( $self->{show_messages} and $notification->{message} )
        {
        push @output, sprintf( "%-*s", $self->{last_message_length}, $notification->{message} );
        $self->{last_message_length} = length( $notification->{message} );
        }

    $self->{current_step}  = 0              if $notification->{finished};
    $self->{max_steps}     = 0              if $notification->{finished};
    $self->{start_time}    = time()     unless $self->{max_steps};

    push @output, ( $self->{show_bar} and $self->{max_steps} ) ? "\r" : "\n";

    if( scalar( keys %{$notification} ) > 2 and not $notification->{message} and not $notification->{step} and not $notification->{finished} )
        {
        return;
        }

    print join( ' ', @output );

    return;
    }

sub next_bar_step
    {
    my $self = shift;
    my $progress = int( $self->{current_step} / $self->{max_steps} * $self->{bar_width} );
    return ( ( $progress + 1 ) / $self->{bar_width} ) * $self->{max_steps};
    }

1;

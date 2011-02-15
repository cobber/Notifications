package Notifications::Progress;

# TODO: Riehm [2011-02-15] this isn't actually working since notifications became objects :-(

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

    $self->{start_time}          = time();
    $self->{current_step}        = 0;
    $self->{max_steps}           = 0;
    $self->{show_bar}            = 1;
    $self->{show_messages}       = 1;
    $self->{show_percent}        = 1;
    $self->{show_duration}       = 1;
    $self->{show_steps}          = 1;
    $self->{bar_width}           = 40;
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

    return unless $notification->event() eq 'progress';

    my $user_data = $notification->user_data();
    local $| = 1;
    $self->{bar_width}      = $user_data->{bar_width}       if $user_data->{bar_width} || 0 >= 1;
    $self->{show_bar}       = $user_data->{show_bar}        if exists $user_data->{show_bar};
    $self->{show_duration}  = $user_data->{show_duration}   if exists $user_data->{show_duration};
    $self->{show_steps}     = $user_data->{show_steps}      if exists $user_data->{show_steps};
    $self->{show_messages}  = $user_data->{show_messages}   if exists $user_data->{show_messages};
    $self->{max_steps}     += $user_data->{expect}          if $user_data->{expect};
    $self->{current_step}  += 1                             if $self->{max_steps} and not $user_data->{finished};
    $self->{current_step}   = $user_data->{step}            if exists $user_data->{step};
    $self->{max_steps}      = $self->{current_step}         if $user_data->{finished};
    $self->{max_steps}      = $self->{current_step}         if $self->{current_step} > $self->{max_steps};

    my @output   = ();

    if( $self->{show_messages} )
        {
        push @output, strftime( "%H:%M:%S", localtime( $notification->timestamp() ) );
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

    if( $self->{show_messages} and my $message = $notification->message() )
        {
        push @output, sprintf( "%-*s", $self->{last_message_length}, $message );
        $self->{last_message_length} = length( $message );
        }

    $self->{current_step}  = 0              if $user_data->{finished};
    $self->{max_steps}     = 0              if $user_data->{finished};
    $self->{start_time}    = time()     unless $self->{max_steps};

    push @output, ( $self->{show_bar} and $self->{max_steps} ) ? "\r" : "\n";

    # try to deduce if it makes sense to print a new line or not
    if( scalar( keys %{$user_data} )
            and not $notification->message()
            and not $user_data->{step}
            and not $user_data->{finished}
            )
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

# TODO: Riehm [2011-02-15] write some documentation for this thing!

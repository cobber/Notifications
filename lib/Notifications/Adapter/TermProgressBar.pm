package Notifications::Adapter::TermProgressBar;

use strict;
use warnings;

use parent qw( Notifications::Observer );

use YAML;

sub new
    {
    my $class = shift;
    my %param = @_;

    my $self = bless {}, $class;

    $self->{progress_bar} = $param{progress_bar}; # TODO: Riehm [2011-02-14] or die

    return $self;
    }

sub accept_notification
    {
    my $self         = shift;
    my $notification = shift;

    # ignore everything except progress notifications
    return unless $notification->event() eq 'progress'; 


    if( $notification->{user_data}{is_finished} )
        {
        # also update next_step so that we definitely update the progress bar one last time
        $self->{next_step} = $self->{step} = $self->{progress_bar}->target();
        }
    else
        {
        # work out which step we're up to if the caller didn't tell us explicitly
        $self->{step} = $notification->{user_data}{step} || ( $self->{step} + 1 );
        }

    # move on if the current position wouldn't visibly change the progress bar
    return unless $self->{step} >= $self->{next_step};

    # actually update the progress bar
    $self->{next_step} = $self->{progress_bar}->update( $self->{step} );

    return;
    }

sub progress_bar
    {
    my $self = shift;
    return $self->{progress_bar};
    }

1;

=head1 NAME

Notifications::Adapter::TermProgress - send progress notifications to Term::ProgressBar

=head1 SYNOPSIS

    use Term::ProgressBar;
    use Notifications::Adapter::TermProgressBar;

    my $progress_bar = Notifications::Adapter::TermProgressBar->new(
                            progress_bar => Term::ProgressBar->new( { count => $number_of_steps } ),
                            );

    $progress_bar->start();

    for( my $count = 0; $count <= $number_of_steps; $count++ )
        {
        progress( '', step => $count ); # all notifications are expected to have a message
        }

=head1 DESCRIPTION

Term::ProgressBar provides a progress bar on STDOUT. This adapter tries to be
intelligent about not calling the progress bar object too often, hopefully
avoiding drastic performance problems.

=head1 OPTIONS

All notifications are expected to contain a message - which means that progress meters also get messages.
If you are just looping over thousands of iterations, feel free to leave the
message unset, however, you should specify a message when starting or finished
a progress bar, and also when explicitly updating the current position.

=over

=item start

Indicate that a new Progress bar should be started (or the existing one should be reset)

=item target

Set the maximum number of steps expected.

=item increase_target

Increase the maximum number of steps expected by this amount.

=item descrease_target

Decrease the maximum number of steps expected by this amount.

=item step

Set the current step number.

=item finished

Indicate that the process has finished - print out one final update to produce a full progress bar.

=back

=head1 EXAMPLES

    my $progress_bar->start();

    my $expected_number_of_finaggles = 5;
    progress( 'finaggling the hoondoggle', start => 1, expect => $expected_number_of_finaggles );

    while( my $doggle = finaggle() )
        {
        progress();
        if( $doggle )
            {
            progress( undef, increase => 10 );     # need undef to keep generic interface happy
            }
        }

    progress( 'successfully finished finaggling', finished => 1 );

=head1 SEE ALSO

Notifications,
Notifications::Progress,
Term::ProgressBar

=head1 AUTHOR

Stephen Riehm, E<lt>sriehm@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Stephen Riehm

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

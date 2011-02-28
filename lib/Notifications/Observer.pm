package Notifications::Observer;

use strict;
use warnings;

use Notifications;

sub new   { return bless {}, shift;                  }
sub start { Notifications->add_observer(    shift ); }
sub stop  { Notifications->remove_observer( shift ); }

sub accept_notification
    {
    my $self         = shift;
    my $notification = shift;

#     use YAML;
#     printf( "%s %s: %s\n%s--\n",
    require POSIX;
    printf( "%s %s: %s\n",
           POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $notification->{timestamp} ) ), 
           uc $notification->{event},
           $notification->{message},
#            Dump( $notification ),
           );
    }

1;

# TODO: Riehm [2011-02-15] write some documentation for this thing!

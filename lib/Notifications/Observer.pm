package Notifications::Observer;

use strict;
use warnings;

use POSIX qw( strftime );

sub new   { return bless {}, shift;                  }
sub start { Notifications->add_observer(    shift ); }
sub stop  { Notifications->remove_observer( shift ); }

sub accept_notification
    {
    my $self         = shift;
    my $notification = shift;

#     use YAML;
#     printf( "%s %s: %s\n%s--\n",
    printf( "%s %s: %s\n",
           strftime( "%Y-%m-%d %H:%M:%S", localtime( $notification->{timestamp} ) ), 
           uc $notification->{event},
           $notification->{message},
#            Dump( $notification ),
           );
    }

1;

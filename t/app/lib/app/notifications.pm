package app::notifications;

use strict;
use warnings;

require Notifications;

sub import
    {
    my $class = caller;
    printf "importing notifications for $class...\n";
    Notifications->import( -export_to_package => $class, qw( detail debug deprecated info step warning exception error app_will_terminate ) );
    }

1;

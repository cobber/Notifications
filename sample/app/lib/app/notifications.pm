package app::notifications;

use strict;
use warnings;

require Notifications;

sub import
    {
    my $class  = shift;
    my $caller = caller;
    my @extra_notifications = @_;
    printf "importing notifications for $caller...\n";
    Notifications->import(
            -export_to_package => $caller,
            qw( detail debug deprecated info step warning exception error app_will_terminate ),
            @extra_notifications,
            );
    }

1;

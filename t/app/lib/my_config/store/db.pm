package config::store::db;

use strict;
use warnings;

use parent qw( config::store );

sub new
    {
    my $class = shift;
    my $param = { @_ };

    my $self = bless {}, $class;
    $self->{name}     = $param->{name};
    $self->{user}     = $param->{user};
    $self->{password} = $param->{password};

    return $self;
    }

sub load
    {
    my $self = shift;

    }

1;

__END__

paths [ user:steve platform:linux ]
    - /home/{user}/.config
    - /net/app/config
    - /system/app/config

paths [ user:steve platform:win32 ]
    - C:\Users\{user}\.config
    - C:\app\config

config_name:
------------
1:paths
2:paths

config_flags:
---------------
1:is_locked
1:is_cachable

config_context:
---------------
1:user:steve
1:platform:linux
2:user:steve
2:platform:win32

config_value:
-------------
1:/home/{user}/.config
1:/net/app/config
1:/system/app/config
2:C:\Users\{user}\.config
2:C:\app\config

package config::store::file;

use strict;
use warnings;
use parent qw( config::store );

use Notifications qw( debug error );

sub load
    {
    my $self = shift;
    debug( sprintf( "loading config file: %s", $self->{file_name} ) );
    $self->{data} = LoadFile( $self->{file_name} );
    $self->{is_loaded} = 1;
    return;
    }

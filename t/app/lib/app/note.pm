package app::note;

use strict;
use warnings;

use parent qw( Notifications::Message );
use YAML;

sub data_as_string
    {
    my $self = shift;

    if( not defined $self->{cached}{data_as_string} )
        {
        $self->{cached}{data_as_string} = ( keys %{$self->{data}} ) ? Dump( $self->{data} ) : '';
        }

    return $self->{cached}{data_as_string};
    }

1;

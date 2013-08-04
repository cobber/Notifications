package config;

# multi-layer config
#
#   top-level:
#       set_value(  );
#       value(  );
#       raw_value(  );
#
#   calculation level:
#
#   stores:
#       have_value(  );
#       can_set_value(  );
#       raw_value(  );

use strict;
use warnings;

use Try::Tiny;

sub new
    {
    my $class = shift;
    my $param = { @_ };

    my $self = bless {}, $class;
    $self->{store_names} = [];          # ordered list of store names
    $self->{stores} = {};               # stores containing raw values - indexed by name
    $self->{cached} = {};               # cached values
    $self->{have_sorted_stores} = 0;

    return $self;
    }

sub add_store
    {
    my $self  = shift;
    my $param = { @_ };
    push @{$self->{stores}}, $param->{store};
    $self->{have_sorted_stores} = 0;
    return;
    }

sub store_names
    {
    my $self  = shift;
    return @{$self->{store_names}};
    }

sub all_stores
    {
    my $self = shift;
    return @{$self->{stores}}{$self->store_names()};
    }

sub store
    {
    my $self = shift;
    my $param = { @_ };
    return $self->{stores}{$param->{store_name}};
    }

sub all_names
    {
    my $self  = shift;
    my $param = { @_ };
    my $names = {};
    foreach my $store ( $self->stores() )
        {
        @{$names}{$store->all_names()} = ();
        }
    return sort keys %{$names};
    }

# special case: ->value( '<name>', %param )
sub value
    {
    my $self  = shift;
    my $name  = shift;
    my $param = { @_ };

    if( $self->{am_getting}{$name} )
        {
        $self->throw( "circular reference: $name" );
        # not reached
        }

    try
        {
        $self->{am_getting}{$name} = 1;
        my @matches = 
                      sort  {
                                $b->[1] <=> $a->[1]     # highest score first - regardless of store
                            or  $a->[2] <=> $b->[2]     # order by store
                            }
                      map  { [ $_, $_->score( context => $context ), $_->origin_store_name() }
                      map  { $_->all_values() }
                      $self->all_stores();
        }
    catch
        {
        # cache an undefined value
        }
    finally
        {
        $self->{am_getting}{$name} = 0;
        };

    return;
    }

# special case: ->value( '<name>', %param )
sub values
    {
    my $self  = shift;
    my $name  = shift;
    my $param = { @_ };
    return;
    }

# special case: ->value( '<name>', %param )
sub all_values
    {
    my $self  = shift;
    my $name  = shift;
    my $param = { @_ };
    return;
    }

1;


package cli;

use app::notifications;

sub run
    {
    my $self = shift;
    debug( "About to run my app" );
    step( step => 1, of => 3 );
    $self->parse_args( @_ );
    step( step => 2, of => 3 );
    $self->run_command();
    debug( "finished my app" );
    step( step => 3, of => 3 );
    app_will_terminate();
    return;
    }

sub parse_args
    {
    my $self = shift;
    deprecated( 'please don\'t do this' );
    }

sub run_command
    {
    my $self = shift;
    exception( "no commands around" );
    foreach my $plugin_file ( qw( app/command/help.pm app/command/version.pm ) )
        {
        eval { require $plugin_file; };
        die "oops: $@\n"    if $@;
        my $plugin_class = $plugin_file;
        $plugin_class =~ s!/!::!g;
        $plugin_class =~ s/.pm$//;
        $plugin_class->do_stuff();
        }
    }

1;

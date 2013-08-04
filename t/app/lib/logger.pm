package logger;

use strict;
use warnings;

use Carp qw( croak );
use File::Spec;
use Notifications::Observer;

sub new 
    {
    my $class = shift;
    my $param = { @_ };
    my $self = bless {}, $class;

    $self->{observer}      = Notifications::Observer->new(
                                                            ''                   => sub { $self->log( shift ); },
                                                            'app_will_terminate' => sub { $self->close();      },
                                                        );
    $self->{log_directory} = $param->{log_directory} || '.';
    $self->{file_name}     = $param->{file_name}     || 'out.log';
    $self->{file_handle}   = undef;
    $self->{statistics}    = {};

    return $self;
    }

sub DESTROY
    {
    my $self = shift;
    $self->close();
    return;
    }

sub file_handle
    {
    my $self = shift;

    if( not $self->{file_handle} )
        {
        my $logfile_path = File::Spec->catfile( $self->{log_directory}, $self->{file_name} );
        printf "opening logfile: $logfile_path\n";
        open( my $file_handle, '>', $logfile_path )    or croak( sprintf( "Can't open %s for logging\n$!", $logfile_path ) );
        printf $file_handle "---------\nStarting to log stuff\n\n";
        $self->{file_handle} = $file_handle;
        }

    return $self->{file_handle};
    }

sub log
    {
    my $self = shift;
    my $note = shift;

    my $file_handle = $self->file_handle();

    printf "writing %s to logfile\n", $note->name();
    printf $file_handle "%-12s(%s) %s\n", uc $note->name() . ':', $note->package(), $note->message();
    if( $note->can( 'data_as_string' ) and my $data = $note->data_as_string() )
        {
        my $indent = ' ' x 12;
        printf $file_handle "%s\n", $data =~ s/^/$indent/mgr;
        }

    $self->{statistics}{$note->name()}++;

    return;
    }

sub close
    {
    my $self = shift;

    if( $self->{file_handle} )
        {
        my $file_handle = $self->{file_handle};
        printf $file_handle "\n\nStatistics:\n";
        foreach my $name ( sort keys %{$self->{statistics}} )
            {
            my $count = $self->{statistics}{$name};
            printf $file_handle "%s: %s\n", $name, $count;
            }

        printf $file_handle "\nClosing logfile\n";

        close( $self->{file_handle} );

        $self->{statistics}  = {};
        $self->{file_handle} = undef;
        }

    return;
    }

1;

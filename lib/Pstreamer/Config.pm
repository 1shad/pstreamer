package Pstreamer::Config;

=head1 NAME

 Pstreamer::Config

=cut
use utf8;
use Carp 'croak';
use File::Spec;
use File::Basename;
use Moo;
use MooX::ConfigFromFile
config_singleton  => 1,
config_prefix     => 'config',
config_identifier => basename($0),
;

with 'MooX::Singleton';

my $CONFIG_DIR = File::Spec->catdir( $ENV{HOME}, '.config', basename($0) );

has [qw(ua ui)] => ( is => 'ro', lazy => 1, builder => 1 );

has user_agent => ( is => 'ro', default =>
    'Mozilla/5.0 (X11; Linux i686; rv:45.0) Gecko/20100101 Firefox/45.0'
);

has header_accept => ( is => 'ro', default =>
    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
);

has cookies_file => ( is => 'ro', default => sub {
    File::Spec->catfile($CONFIG_DIR, 'cookies', 'cookies.txt');
});

has config_file => ( is => 'ro', default => sub {
    File::Spec->catfile( $CONFIG_DIR, 'config.ini' );
});

has [qw(cookies fullscreen ncurses gtk)] => ( is => 'rw' );

# user agent
sub _build_ua {
    my $self = shift;

    eval 'require Mojo::UserAgent';
    croak $@ if $@;

    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name( $self->user_agent );
    
    if ( $self->cookies ) {
        eval 'require Pstreamer::Util::CookieJarFile';
        croak $@ if $@;
        $ua = $ua->cookie_jar( Pstreamer::Util::CookieJarFile->new(
            cookies_file => $self->cookies_file
        ));
    }

    $ua->on( start => sub {
        my ( $ua, $tx ) = @_;
        $tx->req->headers->header( Accept => $self->header_accept );
    });
    
    return $ua;
}

# user interface
sub _build_ui {
    my $self = shift;
    my $ui;
    
    if ( $self->gtk ) {
        $ui = 'Pstreamer::UI::Gtk';
    }
    elsif ( $self->ncurses ) {
        $ui = 'Pstreamer::UI::Curses';
    }
    else {
        $ui = 'Pstreamer::UI::Text';
    }
    
    eval "require $ui";
    croak $@ if $@;

    $ui->new;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut



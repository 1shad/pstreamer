package Pstreamer::Config;

=head1 NAME

 Pstreamer::Config

=cut
use utf8;
use Mojo::UserAgent;
use Term::ReadLine;
use File::Spec;
use File::Basename;
use Pstreamer::Util::CookieJarFile;
use Moo;
use MooX::ConfigFromFile
config_singleton  => 1,
config_prefix     => 'config',
config_identifier => basename($0),
;

with 'MooX::Singleton';

my $CONFIG_DIR = File::Spec->catdir( $ENV{HOME}, '.config', basename($0) );

has [qw(ua term)] => ( is => 'ro', lazy => 1, builder => 1 );

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

has [qw(cookies fullscreen)] => ( is => 'rw' );

sub _build_ua {
    my $self = shift;

    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name( $self->user_agent );
    
    $ua = $ua->cookie_jar(
        Pstreamer::Util::CookieJarFile->new( cookies_file => $self->cookies_file )
    ) if $self->cookies;
    
    $ua->on( start => sub {
        my ( $ua, $tx ) = @_;
        $tx->req->headers->header( Accept => $self->header_accept );
    });
    
    return $ua;
}

sub _build_term {
    my $self = shift;

    my $term = Term::ReadLine->new("term.readline", \*STDIN, \*STDOUT);
    $term->Attribs->ornaments(0);

    return $term;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut



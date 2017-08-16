package Pstreamer::Viewer;

=head1 NAME

Pstreamer::Viewer

=cut

use Pstreamer::Config;
use IPC::Cmd qw(can_run run);
use Moo;

with 'Pstreamer::Role::UA', 'Pstreamer::Role::UI';

has config => ( is => 'ro', default => sub {
    Pstreamer::Config->instance;
});

sub stream {
    my ( $self, $file ) = @_;
    my ( $headers );
    
    return if ( !$file );
    
    ( $file, $headers ) = $self->_parse_url( $file );
    
    $self->_player($file, $headers);
}

sub _player {
    my ( $self, $file, $headers ) = @_;
    my ( $mpv, $cmd, $tx, @fields );

    unless ( $mpv = can_run('mpv') ) {
        $self->error("Ne peut pas executer mpv");
        return;
    };

    # gets header fields from head request
    $tx = $self->ua->head( $file => $headers );
    while ( $tx->result->code == 301 or $tx->result->code == 302 ) {
        # don't go recursive -_-
        last if $file eq $tx->result->headers->header('location');
        $file = $tx->result->headers->header('location');
        $tx = $self->ua->head( $file => $headers );
    }

    $tx = $tx->req->headers->to_string;
    @fields = split /\r\n/, $tx;

    # set up for mpv -http-header-fields
    @fields = map { s/,/\\,/gr } @fields;
    @fields = grep { ! /user-agent|content-length/i } @fields;

    $cmd = [ $mpv ];
    push( @$cmd, '-really-quiet');
    push( @$cmd, '--no-ytdl');
    push( @$cmd, '--fs' ) if $self->config->fullscreen;
    push( @$cmd, '-user-agent');
    push( @$cmd, $self->ua->transactor->name );
    push( @$cmd, '-http-header-fields' );
    push( @$cmd, join ",", @fields );
    
    # in case that cookies will be needed later
    #push( @$cmd, '-cookies'); 
    #push( @$cmd, '-cookies-file');
    #push( @$cmd, 'cookie.txt');
    
    push( @$cmd, $file );
    
    $self->status("MPV en cours" );
    my ( $success ) = run( command => $cmd, verbose => 0 );
    $self->error("MPV ne peut pas lire cette video") unless $success;
    return $success;
}

sub _parse_url {
    my ( $self, $file ) = @_;
    return undef unless $file;
    
    my ( $headers, @temp ) = ( undef, split( /\|/, $file ) );
    ( $file, $headers ) = @temp;
    
    @temp = split /&/, $headers||'';
    $headers = { map { 
        my @t = split /=/;
        { $t[0] => $t[1] // '1' } 
    } grep { $_ } @temp };
    
    return ($file, $headers);
}

1;

=head1 DESCRIPTION

 Play the video with mpv.
 It formats headers and useragent, and pass its to mpv.
 So the file is played as it is in a web browser.

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

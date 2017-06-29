package Pstreamer::Host::Nowvideo;

=head1 NAME

 Pstreamer::Host::Nowvideo

=cut

use feature 'say';
use Mojo::URL;
use Mojo::Util qw(url_escape);
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $dom, $file, $rand, @results );

    $url = $self->_set_url( $url );
    $self->ua->max_redirects(5);
    $tx = $self->ua->get( $url );
    $self->ua->max_redirects(0);
    
    return 0 unless $tx->success;
    $dom = $tx->res->dom;

    if ( $file = $dom =~ /player.src.+?src: *'([^']+)/ ){
        say "--- you must check Nowvideo.pm ---";
        say "url: $url";
        say "file: $file";
        return 0;
    }

    @results = $dom->find('source')
        ->map( sub { { 
            url  => $_->attr('src'),
            name => $_->attr('type'),
            stream => 1,
        } } )
        ->each;
    
    return @results?\@results:0;
}

sub _set_url {
    my ( $self, $url ) = @_;
    ($url) = $url =~ '\/\/(?:www.|embed.)nowvideo.[a-z]{2}\/(?:video\/|embed.+?\?.*?v=)([0-9a-z]+)';
    $url = 'http://embed.nowvideo.sx/embed.php?v='.$url;
    return $url;
}

1;

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/nowvideo.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


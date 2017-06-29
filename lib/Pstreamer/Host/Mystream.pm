package Pstreamer::Host::Mystream;

=head1 NAME

 Pstreamer::Host::Mystream

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $file );

    $url = $self->_set_url($url);

    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    
    ($file) = $tx->res->dom =~ /file: *[\'"](.+?)["\'],/;
    
    return $file?$file:0;
}

sub _set_url {
    my ( $self, $url ) = @_;
    ($url) = $url =~ /(?:http:\/\/|\/\/)(?:www.|embed.|)mystream.(?:la|com)\/(?:video\/|external\/|embed-)([0-9a-zA-Z]+)/;
    $url = 'http://www.mystream.la/external/'.$url;
    return $url;
}

1;

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/mystream.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


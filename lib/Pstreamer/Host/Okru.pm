package Pstreamer::Host::Okru;

=head1 NAME

 Pstreamer::Host::Okru

=cut

use Mojo::Util qw(url_unescape encode);
use Mojo::JSON qw(decode_json);
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $div, $id, $host, $json, @files );
    
    ( $host, $id ) = $self->_parse_url( $url );
    
    $self->ua->max_redirects(1);
    $tx = $self->ua->get( 'http://'.$host.'/videoembed/'.$id );
    $self->ua->max_redirects(0);

    return 0 unless $tx->success;
    $div = $tx->res->dom->at('div[data-module="OKVideo"]');
    return 0 unless $div;
    
    # json string
    $json = $div->attr('data-options');
    $json = decode_json(encode 'UTF-8', $json);
    $json = decode_json(encode 'UTF-8', $json->{flashvars}->{metadata});
    
    # right format, so it just removes the
    # unwanted items and setup url with required headers.
    @files = @{$json->{videos}};
    @files = map {
        delete @{$_} { "seekSchema", "disallowed" };
        $_->{url} = url_unescape( $_->{url} );
        $_->{url} .= '|Referer='.$url.'&Origin=http://ok.ru';
        $_->{stream} = 1;
        $_
    } @files;

    return @files?\@files:0;
}

#http://ok.ru/videoembed/299488774795
sub _parse_url {
    my ( $self, $url ) = @_;
    my @result = $url =~ /https*:\/\/((?:(?:ok)|(?:odnoklassniki))\.ru)\/.+?\/([0-9]+)/;
    return @result;
}

1;

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/ok_ru.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


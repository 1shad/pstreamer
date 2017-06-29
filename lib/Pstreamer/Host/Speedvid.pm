package Pstreamer::Host::Speedvid;

=head1 NAME

 Pstreamer::Host::Speedvid

=cut

use Pstreamer::Util::CloudFlare;
use Pstreamer::Util::Unpacker;
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $cf, $tx, $id, $dom, $js, $JsU, $file );
    
    $id = $self->_get_id($url);

    $JsU = Pstreamer::Util::Unpacker->new;

    $cf = Pstreamer::Util::CloudFlare->new;
    $tx = $self->ua->get( $url );
    $tx = $cf->bypass if $cf->is_active( $tx );
    
    while ( $tx->res->code == 302 ) {
        my $location = $tx->res->headers->header('location');
        $tx = $self->ua->get( $location );
    }

    $dom = $tx->result->dom;

    while ( $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\)\)\))/g ) {
        $js = $1;
        $JsU->packed( \$js );
        $js = $JsU->unpack;
        last if $js =~ /$id/;
    }

    return 0 unless $js;
    return 0 if $js =~ /hgcd06yxp6hf/;
    
    ($file) = $js =~ /{file:.([^']+.mp4)/;
    return $file?$file:0;
}

sub _get_id {
    my ( $self, $url ) = @_;
    ( my $id ) = $url =~ /embed-([^-|^\.]+)/;
    return $id;
}

1;

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/speedvid.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


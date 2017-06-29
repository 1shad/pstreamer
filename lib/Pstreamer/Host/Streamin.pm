package Pstreamer::Host::Streamin;

=head1 NAME

 Pstreamer::Host::Streamin

=cut

use Pstreamer::Util::Unpacker;
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $dom, $js, $file );

    $url = $self->_set_url( $url );
    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    $dom = $tx->res->dom;
    
    ($js) = $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\))\n?<\/script>/;
    return 0 unless $js;
    $js = Pstreamer::Util::Unpacker->new ( packed => \$js )->unpack;
    
    ($file) = $js =~ /file:"([^"]+)"/;
    return $file?$file:0;
}

sub _set_url {
    my ( $self, $url ) = @_;
    my ($id) = $url =~ /.*\/embed-([^-]+).+html/;
    $url = 'http://streamin.to/embed-'.$id.'.html';
    return $url;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

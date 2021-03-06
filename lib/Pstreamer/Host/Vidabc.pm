package Pstreamer::Host::Vidabc;

=head1 NAME

 Pstreamer::Host::Vidabc

=cut

use Pstreamer::Util::Unpacker 'jsunpack';
use Mojo::JSON 'decode_json';
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $js, $json, $file );

    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    
    ($js) = $tx->res->dom =~ /(eval\(function\(p,a,c,k,e,d\)\{.+?\)\)\))/;
    return 0 unless $js;
    
    $js = jsunpack( \$js );
    return 0 unless $js;

    ($json) = $js =~ /sources:\s?(\[.*?\]),/;
    return 0 unless $json;
    
    $json =~ s/file/"stream":"1","url"/g;
    $json =~ s/label/"name"/;
    $json = decode_json( $json );
    $json = [ grep { defined $_->{name} } @$json ];

    return $json;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


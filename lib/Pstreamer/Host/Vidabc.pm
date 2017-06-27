package Pstreamer::Host::Vidabc;

=head1 NAME

 Pstreamer::Host::Vidabc

=cut

use Pstreamer::Util::Unpacker;
use Mojo::JSON 'decode_json';
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ( $dom, $js, $json, $file );

    $dom = $self->ua->get( $url )->result->dom;
    
    ($js) = $dom =~ /(eval\(function\(p,a,c,k,e,d\)\{.+?\)\)\))/;
    return 0 unless $js;
    return 0 unless Pstreamer::Util::Unpacker::is_valid( \$js );
    
    $js = Pstreamer::Util::Unpacker->new( packed => \$js )->unpack;

    ($json) = $js =~ /sources:\s?(\[.*?\]),/;
    return 0 unless $json;
    
    $json =~ s/file/"stream":"1","url"/g;
    $json =~ s/label/"name"/;
    $json = decode_json($json);
    $json = [ grep { defined $_->{name} } @$json ];

    return $json;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


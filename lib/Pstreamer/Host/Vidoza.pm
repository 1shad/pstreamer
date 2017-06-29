package Pstreamer::Host::Vidoza;

=head1 NAME

 Pstreamer::Host::Vidoza

=cut

use Mojo::JSON 'decode_json';
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $json );

    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    
    ($json) = $tx->res->dom =~ /sources:\s?(\[.*\]),/;
    return 0 unless $json;

    $json =~ s/file/"stream":"1","url"/g;
    $json =~ s/label/"name"/g;
    $json = decode_json( $json );

    return $json;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


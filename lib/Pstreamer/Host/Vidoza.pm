package Pstreamer::Host::Vidoza;

=head1 NAME

 Pstreamer::Host::Vidoza

=cut

use Mojo::JSON 'decode_json';
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ( $dom, $json );

    $dom = $self->ua->get( $url )->result->dom;
    
    ($json) = $dom =~ /sources:\s?(\[.*\]),/;
    return 0 unless $json;

    $json =~ s/file/"stream":"1","url"/g;
    $json =~ s/label/"name"/g;
    $json = decode_json($json);

    return $json;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


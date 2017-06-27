package Pstreamer::Host::Vidlox;

=head1 NAME

 Pstreamer::Host::Vidlox

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ( $dom, $file );

    $dom = $self->ua->get( $url )->result->dom;
    
    ($file) = $dom =~ /([^"]+\.mp4)/;
    
    return $file?$file:0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


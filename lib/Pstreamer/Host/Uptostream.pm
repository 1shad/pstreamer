package Pstreamer::Host::Uptostream;

=head1 NAME

 Pstreamer::Host::Uptostream

=cut

use Mojo::URL;
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ( $dom, $file, @results );

    $dom = $self->ua->get( $url )->result->dom;

    @results = $dom->find('source')
        ->map( sub{ { 
            url => Mojo::URL->new($_->attr('src'))->scheme('http')->to_string,
            name => $_->attr('data-res'),
            stream => 1
        } } )
        ->each;

    return @results?\@results:0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


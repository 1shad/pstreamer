package Pstreamer::Host::Cloudy;

=head1 NAME

 Pstreamer::Host::Cloudy

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ( $dom, @results );

    $dom = $self->ua->get( $url )->result->dom;

    @results = $dom->find('source')
        ->map( sub{ { 
            url    => $_->attr('src'), 
            name   => $_->attr('type'),
            stream => 1
        } } )
        ->grep( sub{ $_->{url} } )
        ->each;

    return @results?\@results:0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

package Pstreamer::Host::Estream;

=head1 NAME

 Pstreamer::Host::Estream

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ( $dom, @file );

    $self->ua->max_redirects(1);
    $dom = $self->ua->get( $url )->result->dom;
    $self->ua->max_redirects(0);

    if ( $dom->at('source') ){
        @file = $dom->find('source')
            ->map ( sub { [ $_->attr('src'), $_->attr('label') ] } )
            ->grep( sub { $$_[0] =~ /mp4/ } )
            ->map ( sub { { url => $$_[0], name => $$_[1], stream => 1 } } )
            ->each;
    } else {
        warn "You must check Estream.pm";
    }
    
    return @file?\@file:0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


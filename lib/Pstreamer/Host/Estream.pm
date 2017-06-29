package Pstreamer::Host::Estream;

=head1 NAME

 Pstreamer::Host::Estream

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $dom, @file );

    $self->ua->max_redirects(1);
    $tx = $self->ua->get( $url );
    $self->ua->max_redirects(0);
    return 0 unless $tx->success;
    $dom = $tx->res->dom;

    if ( $dom->at('source') ){
        @file = $dom->find('source')
            ->map ( sub { [ $_->attr('src'), $_->attr('label') ] } )
            ->grep( sub { $$_[0] =~ /mp4/ } )
            ->map ( sub { { url => $$_[0], name => $$_[1], stream => 1 } } )
            ->each;
    } else {
        # let me know !
        warn "You must check Estream.pm";
    }
    
    return @file?\@file:0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


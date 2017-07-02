package Pstreamer::Host::Sample;

=head1 NAME

 Pstreamer::Host::Sample

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $file );

    #$tx = $self->ua->get( $url );
    #return 0 unless $tx->success;
    
    $file = $url.'video.mp4';
    
    return $file?$file:0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


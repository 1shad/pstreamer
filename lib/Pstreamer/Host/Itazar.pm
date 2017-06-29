package Pstreamer::Host::Itazar;

=head1 NAME

 Pstreamer::Host::Itazar

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ($tx, $dom, $file, @results );

    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    $dom = $tx->result->dom;

    while ( $dom =~ /"file":"([^"]+)","type":"([^"]+)","label":"([^"]+)"/g ) {
        push( @results, { 
            url => $1.'|Referer=http://www.itazar.com/itazar3/player.php',
            name => $3,
            stream => 1,
        });
    }
    return @results?\@results:0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


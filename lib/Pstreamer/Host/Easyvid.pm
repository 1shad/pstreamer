package Pstreamer::Host::Easyvid;

=head1 NAME

 Pstreamer::Host::Easyvid

=cut

use feature 'say';
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $dom, $file );

    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    $dom = $tx->res->dom;
    
    ($file) = $dom =~ /{file: *"([^"]+(?<!smil))"/;
    if (!$file and $dom =~ /(eval\s*\(\s*function(?:.|\s)+?)<\/script>/ ){
        # let me know !
        warn "-- You must check Easyvid.pm --";
        #say "-------------------------------";
        #say "-- url: $url";
        #say "-------------------------------";
    }
    return $file?$file:0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


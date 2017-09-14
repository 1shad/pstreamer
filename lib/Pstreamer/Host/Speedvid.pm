package Pstreamer::Host::Speedvid;

=head1 NAME

 Pstreamer::Host::Speedvid

=cut
use Pstreamer::Util::CloudFlare;
use Pstreamer::Util::Unpacker 'jsunpack';
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $cf, $tx, $id, $dom, $js, $file, $headers );
    
    $id = $self->_get_id($url);

    # Get url and bypass CloudFlare if active
    $cf = Pstreamer::Util::CloudFlare->new;
    $tx = $self->ua->get( $url );
    $tx = $cf->bypass if $cf->is_active( $tx );
    
    # In case of redirection
    while ( $tx->res->code == 302 ) {
        my $location = $tx->res->headers->header('location');
        $tx = $self->ua->get( $location );
    }

    $dom = $tx->result->dom;
    # Delete Windows carbages...
    $dom =~ s/\r\n//g;

    # Find the javascript, and unpack it
    while ( $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\)\))</g ) {
        $js = $1;
        next if $js =~ /mp4/;
        next if $js =~ /jwplayer/;
        $js = jsunpack( \$js );
        last;
    }

    return 0 unless $js;

    # It needs two more unpacks
    $js = jsunpack( \$js );
    return 0 unless $js;
    $js = jsunpack( \$js );
    return 0 unless $js;

    # Set Referer in headers
    $headers = { Referer => $url };

    # Find and set up the new url    
    ($url) = $js =~ /href\s*=\s*["']([^"']+)/;
    $url = 'http:'.$url if $url =~ /^\/\//;
    $url = 'http://www.speedvid.net/'.$url if $url =~ /^sp/;

    # Get it
    $tx = $self->ua->get( $url => $headers );
    return 0 unless $tx->success;
    $dom = $tx->res->dom;

    # Find the latest encrypted javascript and unpack it
    while ( $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\)\))\n?</g ) {
        $js = $1;
        next if $js =~ /hgcd06yxp6hf/;
        $js = jsunpack( \$js );
        last;
    }

    return 0 unless $js;
    
    # Tadaa
    ($file) = $js =~ /{file:.([^']+.mp4)/;
    return $file?$file:0;
}

sub _get_id {
    my ( $self, $url ) = @_;
    ( my $id ) = $url =~ /embed-([^-|^\.]+)/;
    return $id;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


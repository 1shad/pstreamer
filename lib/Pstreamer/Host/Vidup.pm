package Pstreamer::Host::Vidup;

=head1 NAME

 Pstreamer::Host::Vidup

=cut

use Mojo::Util 'html_unescape';
use Pstreamer::Util::Unpacker 'jsunpack';
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $dom, $dom2, $file, $id, $key, $code, $code_url );
    my ( @results );
    
    # set up url
    $url = $self->_set_url( $url );
    $id = $self->_get_id( $url );
    $url = 'http://vidup.me/embed-'. $id .'.html';
    
    # get it
    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    $dom = $tx->res->dom;
    
    # find the key
    $key = $self->_get_key( $dom );
    
    # find the code 
    $code_url = 'http://vidup.me/jwv/'.$key;
    $tx = $self->ua->get( $code_url );
    return 0 unless $tx->success;
    
    # decode javascript
    $dom2 = html_unescape( $tx->res->dom );
    $dom2 = jsunpack( \$dom2 );
    return 0 unless $dom2;
    
    # get the code
    ($code) = $dom2 =~ /vt=([^"]+)"/;

    # format datas
    while ( $dom =~ /"file":"([^"]+)","label":"([0-9]+)p"/g ){
        push( @results, {
            url  => $1.'?direct=false&ua=1&vt='.$code,
            name => $2,
            stream => 1,
        });
    }

    if ( ! @results ){
        while ( $dom =~ /label: '([0-9]+)p', file: '([^']+)'/g ) {
            push( @results, {
                url  => $2.'?direct=false&ua=1&vt='.$code,
                name => $1,
                stream => 1,
            });
        }
    }
    
    return @results?\@results:0;
}

sub _set_url {
    my ( $self, $url ) = @_;
    $url =~ s/beta.vidup.me/vidup.me/;
    $url =~ s/embed-//;
    $url =~ s/-\d+x\d+\.html//;
    return $url;
}

sub _get_id {
    my ( $self, $url ) = @_;
    my ( $id ) = $url =~ /vidup.me\/(.*)/;
    return $id;
}

sub _get_key {
    my ( $self, $dom ) = @_;
    my ( $key ) = $dom =~ /var\smpri_Key='([^']+)';/;
    return $key?$key:'';
}

1;

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/vidup.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


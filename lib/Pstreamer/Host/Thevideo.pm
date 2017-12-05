package Pstreamer::Host::Thevideo;

=head1 NAME

 Pstreamer::Host::Thevideo

=cut

use feature 'say';
use Pstreamer::Util::Unpacker 'jsunpack';
use Mojo::Util 'html_unescape';
use Mojo::JSON 'decode_json';
use Moo;

my $DEBUG = 0;

with 'Pstreamer::Role::UA';


sub get_filename{
    my ($self, $url) = @_;
    my ( $tx, $dom, $key, $part, $js, $files, $b, $c, $temp );

    say "BASE URL: ". $url if $DEBUG; 

    $url = $self->_set_url( $url );
    say "MODE URL: " . $url if $DEBUG;

    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;

    $dom = $tx->res->dom;
    
    # find the key
    ($key) = $dom =~ /lets_play_a_game=\'([^\']+)/;
    say "KEY: " . $key if $DEBUG;

    # find the url part
    ($part) = $dom =~ /\(\'rc=.*?\/([^']+)/;
    say "PART: " . $part if $DEBUG;

    # set up the new url
    $url = "https://thevideo.me/".$part."/".$key;
    say "NEW URL: " . $url if $DEBUG;

    # get and unpack result from the new url
    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    $temp = html_unescape( $tx->res->dom );
    
    $js = jsunpack( \$temp );
    return 0 unless $js;
    say "JS : ---\n" . $js . "\n---" if $DEBUG;

    # find var b and c in the decoded js
    ( $b, $c ) = $js =~ /b="([^"]+).*?c="([^"]+)/;
    return 0 unless $b and $c;

    say "B: " . $b if $DEBUG;
    say "C: " . $c if $DEBUG;

    ($files) = $dom =~ /sources:\s*(\[.*?\]),/;
    $files = decode_json( $files );
    return 0 unless $files;

    $files = [ map { {
        url    => $_->{file}."?direct=false&".$b."&".$c,
        name   => 'size: '.$_->{label},
        stream => 1,
    } } @{$files} ];

    return $files?$files:0;
}


#
# ex:
# https://thevideo.me/1a2b3c4e5d6f
# https://thevideo.me/embed-1a2b3c4e5d6f.html
# http://thevideo.me/embed-1a2b3c4e5d6f-816x459.html
#
sub _get_id {
    my ( $self, $url ) = @_;
    
    my ( $id ) = $url =~ /\/(?:embed-)?(\w+)(?:-\d+x\d+)?(?:\.html)?$/;
    return $id;
}

# return the embeded url
sub _set_url {
    my ( $self, $url ) = @_;

    my $id = $self->_get_id( $url );
    $url = "https://thevideo.me/embed-".$id.".html";
    
    return $url;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

package Pstreamer::Host::Netu;

=head1 NAME

 Pstreamer::Host::Netu

=cut

use feature 'say';
use Mojo::Util qw(encode b64_encode b64_decode url_unescape html_unescape);
use Mojo::JSON 'decode_json';
use Pstreamer::Util::Unwise 'unwise';
use Moo;

my $DEBUG = 0;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $dom, $headers, $form, $url2, $host, $wise, $file );
    my ( $at, $iss, $vid, $pass, $referer, $vid_server, $vid_link );
    
    say "URL: $url" if $DEBUG;
    # set up url
    $url = $self->_set_url( $url );
    say "URL: $url" if $DEBUG;

    # get the first page
    $headers = { Referer => 'http://hqq.tv/' };
    
    $self->ua->max_redirects(5);
    $tx = $self->ua->get( $url => $headers );
    $self->ua->max_redirects(0);
    return 0 unless $tx->success;

    $dom = encode 'UTF-8', $tx->res->dom;
    
    # decode javascript
    ($wise) = $dom =~ /(;eval\(function\(w,i,s,e\)\{.+?\)\);)\s*</;
    return 0 unless $wise;
    $wise = unwise( $wise );
    
    # extract vars from js
    $iss = $self->_get_ip;
    ($vid) = $wise =~ /var vid *= *"([^"]+)";/;
    ($at) = $wise =~ /var at *= *"([^"]+)";/;
    ($referer) = $wise =~ /var http_referer *= *"([^"]+)";/;
    $referer||='';
    $pass = '';
    
    # set up url
    $host = 'https://hqq.watch/';
    $url2 = $host.'sec/player/embed_player.php?iss='.$iss.'&vid='.$vid.'&at='.$at;
    $url2 .= '&autoplayed=yes&referer=on&http_referer='.$referer;
    $url2 .= '&pass='.$pass.'&embed_from=&need_captcha=0';
    
    # get second page
    $tx = $self->ua->get( $url2 => $headers );
    return 0 unless $tx->success;
    
    # decode the page
    $dom = unwise( $tx->res->dom );
    $dom = url_unescape( $dom );

    # extract vars
    ($at) = $dom =~ /var\s*at\s*=\s*"([^"]*?)"/;
    my @t = $dom =~ /link_1: ([a-zA-Z]+), server_1: ([a-zA-Z]+)/;
    return 0 unless @t;
    ($vid_link)   = $dom =~ /var\s*$t[0]\s*=\s*"([^"]+)"/;
    ($vid_server) = $dom =~ /var\s*$t[1]\s*=\s*"([^"]+)"/;
    if ( $dom =~ / vid: "([a-zA-Z0-9]+)"}/ ) {
        $vid = $1;
    }
    
    return 0 unless $at and $vid_server and $vid_link;
    
    # set up headers and form for ajax get request
    $headers->{'X-Requested-With'} = 'XMLHttpRequest';
    $form = {
        server_1 => $vid_server,
        link_1   => $vid_link,
        at       => $at,
        adb      => '0/',
        b        => '1',
        vid      => $vid,
    };
    
    # ajax get request
    $tx = $self->ua->get( $host.'/player/get_md5.php'
        => $headers
        => form => $form 
    );
    return 0 unless $tx->success;
    
    # parse json
    $dom = html_unescape( $tx->res->dom );
    $dom = decode_json($dom);

    # extract and decode file url
    # actually each one is valid... but the code is set
    if ( defined $dom->{html5_file} ) {
        say 'HTML5_FILE' if $DEBUG;
        $file = $self->_decodeU( $dom->{html5_file} );
    }
    if( defined $dom->{obf_link} and !$file ) {
        say 'OBF_LINK' if $DEBUG;
        $file = $self->_decodeU( $dom->{obf_link} );
        $file = 'http:'.$file if( $file =~ /^\/\// );
    }
    if( defined $dom->{file} and !$file ) {
        say 'FILE' if $DEBUG;
        $file = $self->_decodeK( $dom->{file}) ;
        $file = b64_decode( $file );
        $file =~ s/\?socket/.mp4.m3u8/;
    }

    say $file if $DEBUG;
    return $file?$file:0;
}


sub _set_url {
    my ( $self, $url ) = @_;
    
    my $id = $self->_get_id( $url );
    return 'http://hqq.tv/player/embed_player.php?vid='.$id.'&autoplay=no';
}

sub _get_id {
    my ( $self, $url ) = @_;
    
    my ($id) = $url =~ /\?v.*?=(\w+)/;
   
    return $id;
}

sub _get_ip {
    my $self = shift;
    my $ip = '192.168.';
    
    $ip .= join('.', map{ int(rand(256)) } 1 .. 2 );

    return b64_encode($ip, '');
}

sub _decodeU {
    my ( $self, $str ) = @_;

    # delete the first char (#)
    $str =~ s/#//;
    return 0 unless( (length $str) % 3 == 0 );

    # Every 3 chars should be preceded by \\u0
    # It's directly decoded below...
    $str =~ s/(...)/pack 'U*', hex($1)/eg;
    return $str;
}

sub _decodeK {
    my $self = shift;
    my $str = shift;
    my $type = shift||'b';

    my @codec_a = qw(G L M N Z o I t V y x p R m z u D 7 W v Q n e 0 b =);
    my @codec_b = qw(2 6 i k 8 X J B a s d H w f T 3 l c 5 Y g 1 4 9 U A);

    if ( $type eq 'd' ) {
        my @tmp = @codec_a;
        @codec_a = @codec_b;
        @codec_b = @tmp;
    }

    my $i = 0;
    while ( $i < @codec_a ) {
        $str =~ s/$codec_a[$i]/___/g;
        $str =~ s/$codec_b[$i]/$codec_a[$i]/g;
        $str =~ s/___/$codec_b[$i]/g;
        $i++;
    }

    return $str;
}

1;

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/netu.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


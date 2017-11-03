package Pstreamer::Host::Speedvid;

=head1 NAME

 Pstreamer::Host::Speedvid

=cut

use utf8;
use feature 'say';
use Pstreamer::Util::CloudFlare;
use Pstreamer::Util::Unpacker 'jsunpack';
use Moo;

my $DEBUG = 0;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $cf, $tx, $id, $dom, $js, $file, $headers );

    say 'URL: '. $url if $DEBUG;

    $id = $self->_get_id($url);
    say 'ID: ' . $id if $DEBUG;

    # Get url and bypass CloudFlare if active
    $cf = Pstreamer::Util::CloudFlare->new;
    $tx = $self->ua->get( $url );
    $tx = $cf->bypass if $cf->is_active( $tx );
    $tx = $self->ua->get( $url );

    # In case of redirection
    while ( $tx->res->code == 302 ) {
        my $location = $tx->res->headers->header('location');
        $tx = $self->ua->get( $location );
    }

    $dom = $tx->result->dom;
    # Delete Windows garbages ...
    $dom =~ s/\r\n//g;
    
    # - Needed for debug -
    #
    #$dom =~ s/(<\/SCRIPT>(-->)?)/<$1\n\n/gi;
    #$dom =~ s/<!--.*?-->//g;
    #
    # Find packets javascripts, and replace it unpacked
    #while ( $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\)\))</g ) {
    #    $js = $1;
    #    while (  $js =~ /eval\(function\(p,a,c,k,e(?:.|\s)+?\)\)/ ) { 
    #        $js = jsunpack( \$js );
    #    }
    #    $dom =~ s/eval\(function\(p,a,c,k,e(?:.|\s)+?\)\)</$js</;
    #}

    # find the aaencoded javascript and unpack it
    $js = aadecode( $dom );
    return 0 unless $js;

    # set up the 'ma' var cookie value
    my $expires = time + 24*60*60*1000;
    my $ma = (int( (900-100)*rand ) + 100 )*( time*(128/4) );
    $ma = "". $ma . $expires;
    say 'MA = ' . $ma if $DEBUG;
    
    # To avoid duplicates in the cookie, as it already exists,
    # 'ma' value is set directly into the cookie rather than in headers.
    for my $c (@{$self->ua->cookie_jar->all}){
        if( $c->name eq 'ma' ) {
            $c->value( $ma );
        }
    }
    
    # set up headers
    $headers = { Referer => $url };

    # Find and set up the new url
    ($url) = $js =~ /href\s*=\s*["']([^"']+)/;
    $url = 'http:'.$url if $url =~ /^\/\//;
    $url = 'http://www.speedvid.net/'.$url if $url !~ /speedvid/;
    say 'URL: '. $url if $DEBUG;

    # Get it
    $tx = $self->ua->get( $url => $headers );
    return 0 unless $tx->success;
    $dom = $tx->res->dom;
    
    # Find the latest encrypted javascript and unpack it
    while ( $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\)\))\n?</g ) {
        $js = $1;
        next if $js =~ /hgcd06yxp6hf/; # wrong one
        $js = jsunpack( \$js );
        last;
    }
    
    return 0 unless $js;

    # Tadaa
    ($file) = $js =~ /{file:.([^']+.mp4)/;
    return $file?$file:0;
}
####
sub _get_id {
    my ( $self, $url ) = @_;
    ( my $id ) = $url =~ /embed-([^-|^\.]+)/;
    return $id;
}
####
# Let's customise aadecode for this site. -`Oo -
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# It finds and returns the decoded aaencoded javascript
# found in $text. 
# Otherwise it returns 0 or undef if not found
# or a decoding error
sub aadecode {
    my ( $text ) = @_;

    my ($aa) = $text =~ /(ﾟωﾟ.+?\(\'_\'\);)/;
    return 0 unless $aa;

    # Formats
    $aa =~ s/\/\*´∇｀\*\///g;
    $aa =~ s/\s//g;
    $aa =~ s/\(?\(\(ﾟДﾟ\)\)\)?/\(ﾟДﾟ\)/g;
    $aa =~ s/\(\(ﾟДﾟ\)\[ﾟoﾟ\]\)/\(ﾟДﾟ\)\[ﾟoﾟ\]/g;

    # extract datas
    ($aa) = $aa =~ /\(ﾟДﾟ\)\[ﾟoﾟ\]\+(.+?)\(ﾟДﾟ\)\[ﾟoﾟ\]\)/;
    return 0 unless $aa;

    # Replace values
    $aa =~ s/\Q(ﾟｰﾟ)/4/g;
    $aa =~ s/\Q(ﾟΘﾟ)/1/g;
    $aa =~ s/\Q(o^_^o)/3/g;
    $aa =~ s/\Q(c^_^o)/0/g;

    # replacements
    $aa =~ s/\((\d)\)/$1/g;

    # eval maths
    while ($aa =~ /\(([+-]?\d+([+-]\d+)+)\)/ ) {
        $aa =~ s/\(([+-]?\d+([+-]\d+)+)\)/$1/gee;
    }

    # Decode
    $aa =~ s{\+?\Q(ﾟДﾟ)[ﾟεﾟ]+\E([0-7](?:\+[0-7])*)\+?}{chr(oct(join('', split(/\+/, $1))))}ge;
    return $aa;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


package Pstreamer::Host::FlashX;

=head1 NAME

 Pstreamer::Host::FlashX

=cut

use feature 'say';
use Mojo::URL;
use Mojo::Util 'html_unescape';
use Moo;

my $DEBUG = 0;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ($tx, $dom, $id, $headers, @links, @results);
    
    say "URL: $url" if $DEBUG;
    
    # set up
    $id = $self->_get_id($url);
    $url = $self->_set_url($url);
    say "URL1: $url" if $DEBUG;

    $headers = {
        Referer => 'http://embed.flashx.tv/embed.php?c='.$id,
        'Accept-Encoding' => 'identity'
    };

    # get the first page
    $tx = $self->ua->get($url => $headers);
    while ( $tx->res->code == 301 or $tx->res->code == 302 ){
        $tx = $self->ua->get( $tx->res->headers->header('location') => $headers );
    }
    return 0 unless $tx->success;
    
    $dom = $tx->result->dom;
    $dom = html_unescape( $dom );

    # load the unlocker js file
    return 0 unless $self->_get_the_js_file( $dom, $id );
    # fake use of javascript. used to test adblock
    return 0 unless $self->_unadblock;
    
    # Find the link to the next page in the html source
    @links = $dom =~ /href=["'](https*:\/\/www\.flashx[^"']+)/g;
    $url = $links[0];
    return 0 unless $url;

    say "URL2: $url" if $DEBUG;
    
    # get the next page
    $tx = $self->ua->get($url => $headers);
    while ( $tx->res->code == 301 or $tx->res->code == 302 ){
        say "LOC:".$tx->res->headers->header('location') if $DEBUG; 
        $tx = $self->ua->get( $tx->res->headers->header('location') => $headers );
    }
    return 0 unless $tx->success;
    $dom = $tx->result->dom;

    # still blocked ?
    if ( $dom =~ /reload the page!/ ) {
        say "BLOCKED" if $DEBUG;
        return 0;
    }
    
    # cheers
    while ( $dom  =~ /{src:\s*\'([^"\',]+)\'.+?label:\s*\'([^"<>,\']+)\'/g ) {
        push( @results, {
            url => $1,
            name => $2,
            stream => 1,
        });
    }
    if ($DEBUG) { say $_->{url} foreach(@results); }
        
    return @results?\@results:0;
}

# set up url
sub _set_url {
    my ( $self, $url ) = @_;
    $url = Mojo::URL->new($url);
    $url = $url->scheme('http');
    $url = Mojo::URL->new('/embed.php?c='.$self->_get_id($url))->to_abs($url);
    
    return $url->to_string;
}

# get id from url
sub _get_id {
    my ( $self, $url ) = @_;
    my ($id) = $url =~ /.*\/\w+-(\w+).*$/;
    return $id;
}

# get host from url
sub _get_host {
    my ( $self, $url ) = @_;
    return Mojo::URL->new( $url )->host;
}

# get special js file from html source
# it is redirected to a php file
# and unlocks the next page
sub _get_the_js_file {
    my ( $self, $dom, $id ) = @_;
    my ($headers, $tx, @t );
    
    $headers = { 
        'Referer' => 'https://www.flashx.tv/dl?playthis',
    };
    
    @t = $dom =~ /src=["\']([^"\']+)/g ;
    @t = map { 'https:'.$_ } grep { /$id/ } @t;
    return 0 unless @t;

    $self->ua->max_redirects(5);
    for( @t ) {
        $tx = $self->ua->get( $_ => $headers );
        if ( ! $tx->success ) {
            say "NotPass: ".$tx->req->url if $DEBUG;
        } else {
            say "Pass: ".$tx->req->url." -- ".$tx->res->code if $DEBUG;
        }
    }
    $self->ua->max_redirects(0);
    return $tx->success;
}

# get js file and simulate its action
sub _unadblock {
    my $self = shift;
    my ( $headers, $dom, $tx, @params );
    
    $headers = { 
        Referer => 'https://www.flashx.tv/dl?playthis',
    };
    
    $tx = $self->ua->get('https://www.flashx.tv/js/code.js' => $headers);
    return 0  if !$tx->success;

    $dom = $tx->res->dom;
    $dom = html_unescape($dom);
    
    @params = $dom =~ /!= null\)\{\n?\s*\$.get\('(.+?)',\s*{(.+?):\s*'(.+?)'\}/;
    
    if ( @params ){
        $tx = $self->ua->get(
            $params[0] => $headers => form => { $params[1] => $params[2] }
        );
        say "UNADBLOCK: YES" if $tx->success and $DEBUG;
        return $tx->success;
    }

    return 0;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


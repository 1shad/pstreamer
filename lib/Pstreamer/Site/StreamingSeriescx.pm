package Pstreamer::Site::StreamingSeriescx;

=head1 NAME

 Pstreamer::Site::StreamingSeriescx

=cut

use utf8;
use Moo;

with 'Pstreamer::Role::Site','Pstreamer::Role::UA','Pstreamer::Role::UI';

has '+url' => ( default => 'http://www.streaming-series.cx/' );

has '+menu' => ( default => sub { {
    'Accueil'      => '/',
    'Action'       => '/category/action/',
    'Animation'    => '/category/animation/',
    'Comédie'      => '/category/comedie/',
    'Documentaire' => '/category/documentaire/',
    'Epouvante'    => '/category/epouvante-horreur/',
    'Fantastique'  => '/category/fantastique/',
} } );


sub search {
    my ( $self, $text ) = @_;
    return $self->ua->get( $self->url => form => { s => $text } );
}

sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, @results );

    return $self->_bypass if defined $self->{params};
    
    $dom = $tx->result->dom;
    for ( $tx->req->url ){
        if ( /\?s=.*/ ) {
            @results = $self->_get_results( $dom );
        }
        elsif( /-streaming.*\/\d+\/$/ ) {
            @results = $self->_get_serie_links( $dom );
        }
        elsif( /-streaming.*\/$/ ){
            @results = $self->_get_serie_infos( $dom );
        }
        else { 
            @results = $self->_get_results( $dom );
        }
    }
    
    return @results;
}

sub _get_results {
    my ( $self, $dom ) = @_;
    my @results;

    @results = $dom->find('.movief a')
        ->map( sub { { 
            url => $_->attr('href'),
            name => $_->text =~ s/\sStreaming//r,
        } } )
        ->each;
    
    push( @results, $self->_find_next_page($dom) );
    return @results;
}

sub _get_serie_infos {
    my ( $self, $dom ) = @_;
    my ( $name, @results );

    $name = $dom->at('title')->text;
    $name =~ s/(.*)(Saison)\s(\d+)(.*)?/$3<10?$1."S0".$3:$1."S".$3/e;

    @results = $dom->find('.keremiya_part a')
        ->map( sub { {
            url => $_->attr('href'),
            name => $name."E".$_->all_text
        } } )
        ->each;

    return @results;
}

sub _get_serie_links {
    my ( $self, $dom ) = @_;
    my @results;

    @results = $dom->find('.filmicerik iframe')
        ->map( sub { [
            $_->attr('src'),
            $_->previous->text =~ s/Lecteur\s//r,
            $_->parent->at('.lg')->text =~ s/.*\((.+)\)/$1/r,
        ] } )
        ->map( sub { {
            url => $self->url,
            params => $$_[0],
            name => $$_[1].' - '.$$_[2],
        } } )
        ->each;

    return @results;
}

sub _find_next_page {
    my ( $self, $dom ) = @_;
    my ( $next, @result );

    $next = $dom->at('.current');
    return () unless $next;

    $next = $next->next;
    
    push(@result, { 
        name => ">> page ".$next->text,
        url => $next->attr('href'),
    } );

    return @result;
}

sub _bypass { # protect-stream
    my $self = shift;
    my ( $dom , $headers, $k, $res, $ps );
    my $url = 'http://www.protect-stream.com/secur2.php';

    $ps = $self->{params};
    $self->{params} = undef;

    $headers = {
        Host    => 'www.protect-stream.com',
        Referer => $ps,
    };

    $dom = $self->ua->get($ps)->result->dom;
    ($k) = $dom =~ /var k=\"([^<>\"]*?)\";/;
    warn "protect-stream: k non trouvé" and return () if !$k;
    
    $self->wait_for(5, "protect-stream:");

    $dom = $self->ua->post( $url => $headers => form => { k => $k })
        ->result->dom;

    ($k) = $dom =~ /var k=\"([^<>\"]*?)\";/;
    warn "protect-stream: lien encore protégé" and return () if $k;
    
    $res = $dom->at('iframe');
    if ( !$res ){
        $res = $dom->at('a[class="button"]')->attr('href');
    }else{
        $res = $res->attr('src');
    }

    return $res?({ url => $res }):();
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


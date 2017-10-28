package Pstreamer::Site::SokroStream;

=head1 NAME

 Pstreamer::Site::SokroStream

=cut

use utf8;
use Pstreamer::Util::CloudFlare;
use Mojo::URL;
use Mojo::Util 'trim';
use Moo;

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

has '+url' => ( default => 'http://sokrostream.ws/' );

has '+menu' => ( default => sub { { 
    'Accueil'                => '/',
    'Films derniers ajouts'  => "/categories/films-streaming",
    'Series derniers ajouts' => "/categories/series-streaming",
    'Les plus vues'          => "/les-films-les-plus-vues-2",
    'Les plus commentés'     => "/les-films-les-plus-commentes-2",
    'Les mieux notés'        => "films-les-mieux-notes-2",
} } );

#------[ SEARCH ]----------------------------------------------------
sub search {
    my ( $self, $text ) = @_;
    my $headers = { Referer => $self->url };
    my $cf = Pstreamer::Util::CloudFlare->new;
    
    my $tx = $self->ua->get( 
        $self->url."search.php" => $headers  => form => { q => $text }
    );
    
    if( $cf->is_active($tx) ){
        $tx = $cf->bypass;
        $tx = $self->ua->get( $tx->req->url => $headers );
    }
    
    return $tx;
}

#-------[ GET RESULTS ]----------------------------------------------
sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, @results);

    return () unless defined $tx;
    $dom = $tx->result->dom;

    for ( $tx->req->url ) {
        if   ( /\?q=.*/  ) {
            @results = $self->_search_results( $dom, "default" );
        }
        elsif( /categories\//){
            @results = $self->_search_results( $dom, "default" );
        }
        elsif( /series\// ) {
            @results = $self->_search_results( $dom, "saisons" );
        }
        elsif( /series-tv\// ) {
            @results = $self->_search_results( $dom, "episodes" );
        }
        elsif(  /serie\// || /films\// ) {
            if ( defined $self->{params} ){
                @results = $self->_decode_link( $dom, $_ );
            } else {
                @results = $self->_get_links( $dom );
            }
        }
        else { @results = $self->_search_results( $dom, "default" ); }
    }
    return @results;
}

#-------[ SEARCH RESULTS ]-------------------------------------------
sub _search_results {
    my ( $self, $dom, $param ) = @_;
    my ( @results, $title ) = ( undef, undef );
    
    my %pattern = (
        default => '.movief a',
        saisons => '.films-container.seasons .movief a',
        episodes => '.films-container.serie-container .movief2 a',
    );

    if ( $param eq "saisons" or $param eq "episodes" ) {
        $title = trim( $dom->at('h1')->text );
        $title =~ s/\sen\sStreaming// ;
    }

    my %tr = (
        'tr-dublaj'  => 'FR',
        'tr-altyazi' => 'VOSTFR',
    );

    @results = $dom->find($pattern{$param})
        ->map( sub { 
            my $t = $_->parent->next;
            my $l = $_->parent->parent->at('span');
            $t = $t->text ? $t->text : undef if $t;
            $l = $tr{$l->attr('class')}?$tr{$l->attr('class')}:$l->text if $l;
            {
                name => join( ' - ', grep defined, $title, $_->text, $l, $t ),
                url => $_->attr('href'),
            } 
        } )
        ->each;
    
    push(@results, $self->_find_next_page($dom) );
    return @results;
}

#-------[ GET LINKS ]------------------------------------------------
sub _get_links {
    my ( $self, $dom ) = @_;
    my ( $url, @results );
    
    $url = $dom->at('link[rel="canonical"]')->attr('href');
    
    @results = $dom->find('li.seme')
        ->map('find', 'img,input')
        ->map( sub { [
            trim( $$_[0]->parent->text ),
            $$_[1]->attr('src') =~ s/.*\/(.+)\.png$/uc($1)/er,
            $$_[0]->parent->parent->parent->attr('data-iframe'),
        ] } )
        ->map( sub { {
            name   => $$_[0].' - '.$$_[1],
            params => $$_[2],
            url    => $url,
        } } )
        ->each;
    
    return @results;
}

#-------[ DECODE LINK ]----------------------------------------------
sub _decode_link {
    my ( $self, $dom, $u  ) = @_;
    my ( $url, $tx, $param, $iframe, $headers, @result );
    
    $param = $self->{params};
    $self->{params} = undef;
    
    $headers = { Referer => $u };
    $tx = $self->ua->get( $param, $headers );
    return () unless $tx->success;
    ($url) = $tx->res->dom =~ /url=([^"]+)/;
    
    push( @result, { url => $url, name => "sokro" } );
    return @result;
}

#-------[ FIND NEXT PAGE ]-------------------------------------------
sub _find_next_page {
    my ( $self, $dom ) = @_;
    my ( $next, $name, @result );
    
    $next = $dom->at('.current');
    return () unless ($next && $next->next);
    $next = $next->next;
    $next = Mojo::URL->new($next->attr('href'));
    $next = $next->to_abs($self->url) unless $next->is_abs;
    $name = $next =~ s/.*(page)\/(.*)/$1 $2/r;
    push(@result, { name => ">> ".$name, url => $next->to_string } );
    return @result;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

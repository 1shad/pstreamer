package Pstreamer::Site::LibreStream;

=head1 NAME

 Pstreamer::Site::LibreStream

=cut

use Mojo::Util 'trim';
use Moo;

has url => ( is => 'ro', default => 'http://ls-streaming.com/' );

has menu => ( is => 'ro', default => sub { {
    'Accueil'  => '/',
    'Series'   => '/series/',
    'Films'    => '/films/',
    'Films HD' => '/films-hd/',
    'Dvdrip'   => '/quality/dvdrip/',
    'Bdrip'    => '/quality/bdrip/',
} } );

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

sub search {
    my ( $self, $text ) = @_;
    return $self->ua->get( $self->url => form => { q => $text } );
}

sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom , @results );

    $dom = $tx->result->dom;
    
    if ( $dom->at('.storydetails') ) {
        for ( $dom->at('.storydetails a:first-child')->attr('href') ) {
            if    ( /serie/ ) { return $self->_get_serie_links( $dom ); }
            elsif ( /film/ )  { return $self->_get_film_links( $dom );  }
        }
    }
    
    @results = $dom->find('.libre-movie.libre-movie-block')
        ->map( 'find','a:last-child,.maskquality,.masklangue,.VOSTFR2, h3' )
        ->map( sub { {
            url  => $$_[0]->attr('href'),
            name => join ' - ', reverse map {
                if ( $_->attr('class') and $_->attr('class') =~ /vostfr/i ) {
                    'VOSTFR'
                } else {
                    $_->all_text
                }
            } splice( @{$_}, 1 ) ,
        } } )
        ->each;

    push( @results, $self->_find_next_page($dom) );
    return @results;
}

sub _get_serie_links {
    my ( $self, $dom ) = @_;
    my ( @results );

    @results = $dom->find('.tab-buttons-panel')
        ->map( 'find', 'iframe, .episodetitle, .episode-id' )
        ->map( sub { [
            $$_[0]->attr('src'),
            $$_[0]->attr('src') =~ s/http:\/\/([\w]+).*/uc($1)/er,
            $$_[1]->text =~ s/\s(.*)\sstreaming\sgratuit/$1/ir,
            $$_[2]->text,
        ] } )
        ->map( sub { {
            url  => $$_[0],
            name => $$_[2].' '.$$_[3].' - '.$$_[1],
        } } )
        ->each;

    return @results;
}

sub _get_film_links {
    my ( $self, $dom ) = @_;
    my ( $title, @results, %hosters );

    $title = $dom->at('meta[property="og:title"]')->attr('content');

    %hosters = $dom->find('.etabs li a')
        ->map( sub { [$_->attr('href') =~ s/#//r, uc( trim( $_->text ) ) ] } )
        ->map( sub { { $$_[0] => $$_[1] } } )
        ->each;

    @results = $dom->find('.tab-buttons-panel iframe')
        ->map( sub { { 
            url => $_->attr('src'),
            name => $title.' - '.$hosters{$_->parent->attr('id')},
        } } )
        #->grep( sub { defined $_->{name} } )
        ->each;

    return @results;
}

sub _find_next_page {
    my ( $self, $dom ) = @_;
    my @result;

    $dom = $dom->at('.navigation > a > .fa.fa-angle-right');
    return () unless $dom;
    $dom = $dom->parent;
    return () if $dom->attr('href') eq "#";
    push( @result, { 
        url => $dom->attr('href'),
        name => '>>'.$dom->attr('href') =~ s/.*\/page\/(.*)\// page $1/r },
    );

    return @result;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

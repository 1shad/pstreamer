package Pstreamer::Site::PapyStreaming;

=head1 NAME

 Pstreamer::Site::PapyStreaming

=cut

use utf8;
use Mojo::JSON 'decode_json';
use Mojo::Util 'trim';
use Mojo::URL;
use Moo;

has url => ( is => 'ro', default => 'http://papy-streaming.org/' );

has menu => ( is => 'ro', default => sub{ {
    'Accueil'          => '/',
    'Film Streaming'   => '/film-streaming-hd/',
    'Series Streaming' => '/series-streaming-hd/',
    'Derniers ajouts'  => '/nouveaux-films-hd/',
    'Populaire'        => '/populaire-hd/',
    'Les plus vues'    => '/de-visite/',
    'Les mieux notées' => '/de-vote/',
} } );

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

sub search {
    my ( $self, $text ) = @_;
    return $self->ua->get( $self->url => form => { s => $text } );
}

sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, @results );
    
    $dom = $tx->result->dom;
    
    for( $tx->req->url ) {
        if ( /film\/|episode/) {
            @results = $self->_get_hosters_links($dom);
        }
        elsif ( /(#.*)$/ )  {
            @results = $self->_get_serie_episodes( $dom, $1 );
        }
        elsif ( /serie\// ) {
            @results = $self->_get_serie_seasons($dom, $_);
        }
        else {
            @results = $self->_get_default_links($dom);
        }
    }
    
    return @results;
}



sub _get_default_links {
    my ( $self, $dom ) = @_;
    my ( @results );

    @results = $dom->find('.info a')
        ->grep( sub { $_->attr('href') } )
        ->map( sub { {
            url => $_->attr('href'),
            name => trim($_->text).' - '.$_->parent->next->text,
        } } )
        ->each;
    
    push( @results, $self->_find_next_page($dom) );
    return @results;
}

sub _get_serie_episodes {
    my ( $self, $dom, $id ) = @_;
    my ( @results );

    @results = $dom->find("$id a")
        ->map( sub { {
            url  => $_->attr('href'),
            name => $_->attr('title'),
        } } )
        ->each;

    return @results;
}

sub _get_serie_seasons {
    my ( $self, $dom, $url ) = @_;
    my ( @results );
    
    @results = $dom->find('.season-header a')
        ->grep( sub { $_->attr('href') =~ /#/ } )
        ->map( sub { {
            url => $url.$_->attr('href'),
            name => $_->attr('title') =~ s/Temporada/Saison/r,
        } } )
        ->each;

    return @results;
}

sub _get_hosters_links {
    my ( $self, $dom ) = @_;
    my ( @results, $links );

    $links = $self->_get_repron_links($dom);
    return () unless defined $links;

    @results = $dom->find('table > tbody > tr')
        ->map('find', 'td' )
        ->map( sub { [ 
            $_->[1]->at('a')->attr('href') =~ s/#embed//r,
            $_->[2]->at('span')->text,
            $_->[3]->at('img')->attr('src') =~ s/.*\/(\w+)\.png$/uc($1)/er,
            $_->[4]->text,
        ] } )
        ->map( sub { {
            url  => $$links[ $_->[0] ] ,
            name => $_->[1].' '.$_->[2].' '.$_->[3],
        } } )
        ->each;

    @results = map {
        if ( $_->{url} =~ /player\.papystreaming/ ) {
            @{ $self->_get_papy_player_links( $_ ) };
        } else { $_ }
    } @results;
    
    return @results;
}

sub _get_repron_links {
    my ( $self, $dom ) = @_;
    my ( $json );
    
    ($json) = $dom =~ /repron_links\s?=\s?(.*?)<\/script>/;
    return undef unless defined $json;
    $json = decode_json($json);
    $json = [ map { $_->{link} } @$json ];
    $json = [ map { s/^\/\//$self->url->scheme.':\/\/'/er } @$json ];
    $json = [ map { s/\/\/\/\//\/\//r } @$json ]; # clean up if needed

    return $json;
}

sub _get_papy_player_links {
    my ( $self, $item ) = @_;
    my ( $tx, $json ) = ( undef, [] );

    $tx = $self->ua->get( $item->{url} );
	my $headers = { Referer => $item->{url} };
    
    if ( my $iframe = $tx->res->dom->at('iframe') ) {
        $tx = $self->ua->head( $iframe->attr('src') => $headers );
        my $src = $iframe->attr('src');

        while ( $tx->res->code == 301 or $tx->res->code == 302 ) {
            $headers->{Referer} = $src;
            $src = $tx->res->headers->header('location');
            $tx = $self->ua->head( $src => $headers );
        }

        $json = [ {
            url  => Mojo::URL->new( $src )->host('drive.google.com'),
            name => $item->{name},
        } ];
    }
    
    return $json;
}

sub _find_next_page {
    my ( $self, $dom ) = @_;
    my @result;

    $dom = $dom->at('.pagination > .active');
    return () unless $dom;
    $dom = $dom->next;
    return () unless $dom;
    
    push( @result, { 
        url => $dom->at('a')->attr('href'),
        name => '>>'.$dom->at('a')->attr('href') =~ s/.*\/page\/(.*)\// page $1/r },
    );

    return @result;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

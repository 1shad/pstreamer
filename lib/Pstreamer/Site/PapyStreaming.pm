package Pstreamer::Site::PapyStreaming;

=head1 NAME

 Pstreamer::Site::PapyStreaming

=cut

use utf8;
use Pstreamer::Util::Unjuice 'unjuice';
use Mojo::JSON 'decode_json';
use Mojo::Util 'trim';
use Mojo::URL;
use Moo;

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

has '+url' => ( default => 'http://papy-streaming.org/' );

has '+menu' => ( default => sub { {
    'Accueil'          => '/papystreaming-2017/',
    'Film Streaming'   => '/film-streaming-hd-2017/',
    'Series Streaming' => '/series-streaming-hd/',
    'Derniers ajouts'  => '/nouveaux-films-hd/',
    'Populaire'        => '/populaire-hd/',
    'Les plus vues'    => '/de-visite/',
    'Les mieux notées' => '/de-vote/',
} } );

sub search {
    my ( $self, $text ) = @_;
    my $url = Mojo::URL->new('/')->to_abs( $self->url );
    return $self->ua->get( $url => form => { s => $text } );
}

sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, @results );

    return $self->_handle_params() if $self->params;

    $dom = $tx->result->dom;
    
    for( $tx->req->url ) {
        if ( /film\/|episode/) {
            @results = $self->_get_hosters_links($dom, $_);
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
        ->grep( sub { $_->text ne ' ' } )
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
    my ( $self, $dom, $from_url ) = @_;
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
        if ( $_->{url} =~ /papy-?streaming\.org/ ) {
            $_->{params} = {
                url  => $_->{url},
                name => $_->{name},
                from => $from_url,
            };
            $_->{url} = $self->url;
            $_;
        }
        else { $_ }
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

sub _handle_params {
    my $self = shift;
    my @results;
    my $params = $self->params;

    if ( $params->{url} =~ /player2\.papystreaming/ ) {
        @results = $self->_get_papy_player2_links( $params );
    }
    elsif ( $params->{url} =~ /player\.papystreaming/ ) {
        @results = $self->_get_papy_player_links( $params );
    }
    elsif( $params->{url} =~ /stream\.papy/ ) {
        @results = $self->_get_papy_stream_links( $params );
    }
    else {
        @results = ();
    }

    $self->params( undef );
    return @results;
}

sub _get_papy_player_links {
    my ( $self, $item ) = @_;
    my ( $tx, @result );

    my $headers = { Referer => $item->{from} };
    $tx = $self->ua->get( $item->{url} => $headers );
    $headers = { Referer => $item->{url} };
    
    if ( my $iframe = $tx->res->dom->at('iframe') ) {
        $tx = $self->ua->head( $iframe->attr('src') => $headers );
        my $src = $iframe->attr('src');

        while ( $tx->res->code == 301 or $tx->res->code == 302 ) {
            $headers->{Referer} = $src;
            $src = $tx->res->headers->header('location');
            $tx = $self->ua->head( $src => $headers );
        }

        push ( @result,  {
            url  => Mojo::URL->new( $src )->host('drive.google.com'),
            name => $item->{name},
        });
    }
    
    return @result;
}

sub _get_papy_player2_links {
    my ( $self, $item ) = @_;
    my ( $tx, $juice, @result );
    
    my $headers = { Referer => $item->{from} };
    $tx = $self->ua->get( $item->{url} => $headers );
    return () unless $tx->success;
    
    $self->ua->inactivity_timeout(20);

    ($juice) = $tx->res->dom =~ /(JuicyCodes.Run\(.+?\);)/;

    $juice = unjuice( $juice );
    return () unless $juice;

    $juice =~ s/.*sources:\[\{["']file["']:["']([^"']+).*/$1/;
    return () unless $juice;

    push ( @result, {
        url  => $juice,
        name => $item->{name},
        stream => 1,
    });

    return @result;
}

sub _get_papy_stream_links {
    my ( $self, $item ) = @_;
    my ( $tx, $file, @result );

    my $headers = { Referer => $item->{from} };
    $tx = $self->ua->get( $item->{url} => $headers );

    ($file) = $tx->res->dom =~ /file:\s*["\']([^"\']+)/;
    return () unless $file;

    push ( @result, {
        url => $file,
        name => $item->{name},
        stream => 1,
    });
    
    return @result;
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

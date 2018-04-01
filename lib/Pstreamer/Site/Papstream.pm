package Pstreamer::Site::Papstream;

=head1 NAME

 Pstreamer::Site::Papstream

=cut

use utf8;
use Mojo::URL;
use Mojo::Util 'trim';
use Moo;

with 'Pstreamer::Role::Site','Pstreamer::Role::UA';

has '+url' => ( default => 'http://www.papstream.net/' );

has '+menu' => ( default => sub { {
    'Accueil' => '/',
    'Films'   => '/films.html',
    'Series'  => '/series.html',
    'Animes'  => '/animes.html',
}});

sub search {
    my ( $self, $text ) = @_;
    my $url = $self->_to_abs('/rechercher');
    my $headers = {'X-Requested-With' => 'XMLHttpRequest'};

    $self->ua->post( $url => $headers => form => {
        story     => $text,
        subaction => 'search',
        do        => 'search',
    });
}

# dispatch en fonction de l'url
sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, @results );
    
    return $self->_video_resolver if $self->params;
    
    $dom = $tx->result->dom;
    
    for ( $tx->req->url ) {
        if ( /\/page\-\d+.html$/ ) {
            @results = $self->_get_links($dom);
        } elsif ( /(series|animes)\/.*episode\-\d+\-/ || /\/films\/.+\.html$/ ) {
            @results = $self->_get_videos($dom, $_);
        } elsif ( /(series|animes)\// ) {
            @results = $self->_get_seasons($dom);
        } else {
            @results = $self->_get_links($dom);
        }
     }   
    return @results;
}

# La liste des liens de la vidéo
sub _get_videos {
    my ( $self, $dom, $from ) = @_;
    my @results;
    my $title = $dom->at('input[name="_wpnonce"]')->attr('value');

    @results = $dom->find('#fplay')
        ->map( sub { [ # creer le premier tableau [ url, nom, langue ]
            $_->at('a')->attr('rel'),
            trim( $_->at('#player_v_DIV_5')->text ),
            $_->at('img')->attr('src') =~ s/.*\/(\w+)\.png$/uc($1)/er
        ]})
        ->map( sub { { # creer le hash 
            name => join( ' - ', $title, $_->[1], $_->[2] ),
            url  => $_->[0]
        }})
        ->map(sub {{ # modifie le hash pour le passer au resolver via "params"
            $_->{params} = { url => $_->{url}, name => $_->{name}, from => $from };
            $_->{url} = $self->url;
            $_;
        }})
        ->each;
}

# Trouve l'url de l'hébergeur de la vidéo
sub _video_resolver {
    my ( $self ) = @_;
    my ( $tx, $headers, $res, $params );

    $params = $self->params;
    
    $res = [];
    $headers = { Referer => $params->{from} };

    # head request
    $tx = $self->ua->head( $params->{url} => $headers );

    # Prend l'url de redirection
    if ( $tx->res->code == 301 or $tx->res->code == 302) {
        $res = [{
            url  => $tx->res->headers->header('location'),
            name => $params->{name},
        }];
    }

    $self->params(undef);
    return @$res;    
}

# La liste des saisons ou des episodes ( series, animes )
sub _get_seasons {
    my ( $self, $dom ) = @_;
    my @results;

    @results = $dom->find('#full-video a')
        ->map( sub { {
            name => $_->attr('title') =~ s/^\w+\s(.*)\s\w+\s\w+$/$1/r,
            url  => $self->_to_abs( $_->attr('href') )
        } } )
        ->each;
}

# La liste des liens sur les pages principales
# ( -> accueil, films, series, animes )
sub _get_links {
    my ( $self, $dom ) = @_;
    my @results;
    
    @results = $dom->find('.shortstory-in')
        ->map( 'find', '.film-rip, .film-language, .short-link' )
        ->map( sub { my @t = reverse @{$_}; {
            name => join( ' - ', map { $_->all_text } grep { defined } @t ),
            url  => $self->_to_abs( $t[0]->at('a')->attr('href') ),
        } } )
        ->map( sub { $_->{url} =~ s/\/(\w+)\/(\w+)\//\/$2\//; $_ }) # repare lien de recherche
        ->each;
    push( @results, $self->_next_page($dom) );
    return @results;
}

# trouve le lien vers la page suivante
sub _next_page {
    my ( $self, $dom ) = @_;
    my @result;

    @result = $dom->find('div.pages-numbers span')
        ->grep( sub { ! $_->matches('.nav_ext') })
        ->map ( sub { $_->next })
        ->grep( sub { $_ } )
        ->map ( sub { {
            url => $self->_to_abs( $_->attr('href') ),
            name => '>> page '.$_->text,
        }})
        ->each;
}

# utilitaire
sub _to_abs {
    my ( $self, $path) = @_;
    return Mojo::URL->new( $path )->to_abs( $self->url )->to_string,
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


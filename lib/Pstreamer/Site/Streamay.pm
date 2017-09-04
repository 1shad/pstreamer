package Pstreamer::Site::Streamay;

=head1 NAME

 Pstreamer::Site::Streamay

=cut

use utf8;
use Mojo::Util 'html_unescape';
use Mojo::JSON 'decode_json';
use Mojo::Util 'trim';
use Mojo::URL;
use Moo;

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA'; 

has '+url' => (
    default => 'http://streamay.ws/',
);

has '+menu' => ( default => sub { {
    'Accueil'      => '/',
    'Series'       => '/series',
    'Mangas'       => '/mangas',
    'Emissions'    => '/emissions',
    'Films'        => '/films',
    'Films a voir' => '/film-a-voir',
} } );

sub search {
    my ( $self, $text ) = @_;
    my $headers = { Referer => $self->url };
    return $self->ua->post( $self->url.'search'
        => $headers 
        => form => { k => $text } 
    );
}

sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, @results );

    # params: host link to resolve
    if ( $self->params ) {
        $tx = $self->ua->get( $self->params );
        $self->params( undef );
    }
    
    $dom = $tx->res->dom;
    
    for ( $tx->req->url ) {
        if ( /\/search$/ ) {
            @results = $self->_get_search( $dom );
        }
        elsif ( /series\/[\w-]+$/ ) {
            @results = $self->_get_serie_episode_list( $dom );
        }
        elsif ( /mangas\/[\w-]+$/ ) {
            @results = $self->_get_manga_episode_list( $dom );
        }
        elsif ( /emissions\/[\w-]+$/ ) {
            @results = $self->_get_emission_hosts_list( $dom );
        }
        elsif ( /read\/mepisode\/\d+\/\d+$/ ) {
            @results = $self->_get_manga_hosts_list( $dom );
        }
        elsif ( /(\.html|series.+\/saison.+\/episode.+)$/ ) {
            @results = $self->_get_hosts_list( $dom );
        }
        elsif ( /streamerM?Episode|streamer(Serie)?\/\d+\/\w+/ ) {
            @results = $self->_get_host_url( $dom );
        }
        elsif ( $_ eq $self->url ) {
            @results = $self->_get_homepage( $dom );
        }
        else {
            @results = $self->_get_others( $dom );
        }

    }

    return @results;
}

#-------[ FRONT PAGES ]--------------------------------------------------------
#
sub _get_search {
    my ( $self, $dom ) = @_;
    my ( $json, @results );
    
    $dom =~ s/<.*?>//g;
    $dom = html_unescape( $dom );
    $json = decode_json( $dom );

    foreach my $i ( @$json ) {
        push( @results, {
            url  => $i->{result}->{url},
            name => $i->{result}->{title} .' - '. $i->{type},
        });
    }
    
    return @results;
}

sub _get_homepage {
    my ( $self, $dom ) = @_;
    my @results;
   
    @results = $dom->find('a.movie_single .title')
        ->map( sub { {
            url  => $_->parent->parent->attr('href'),
            name => $_->all_text,
        }})
        ->each;

    return @results;
}

sub _get_others {
    my ( $self, $dom ) = @_;
    my ( @results );
   
    @results = $dom->find('.movie')
        ->map( 'find', '.qualitos,.title' )
        ->map( sub { [
            $$_[0]->attr('href') ? $$_[0]->attr('href') : $$_[1]->attr('href'),
            $$_[0]->all_text,
            $$_[1] ? $$_[1]->all_text : undef,
        ] } )
        ->map( sub { {
            name => join(" - ", grep{ defined } ($$_[2], $$_[1]) ) =~ s/\n//gr,
            url  => $$_[0],
        } } )
        ->each;

    push( @results, $self->_find_next_page($dom) );
    return @results;
}

#-------[ EPISODE LIST ]-------------------------------------------------------
#
sub _get_serie_episode_list {
    my ( $self, $dom ) = @_;
    my @results;

    @results = $dom->find('.item')
        ->map( sub { {
            name => join(
                ' - ',
                splice(@{Mojo::URL->new( $_->attr('href') )->path->parts},1,3)
            ),
            url  => $_->attr('href'),
        } } )
        ->each;

    return @results;
}

sub _get_manga_episode_list {
    my ( $self, $dom ) = @_;
    my ( $title, $id, $tx, $json, @results );

    $title = $dom->at('h1.serieTitle')->all_text;
    $title =~ s/\s*streaming\s*//i;
    $id = $dom->at('.chooseEpisodeManga')->attr('data-id');
    
    $tx = $self->ua->get( $self->url.'read/mepisodes/'.$id );
    return () unless $tx->success;

    $json = html_unescape( $tx->res->dom );
    $json = decode_json( $json );
    $json = $json->{episodes};

    @results = map { {
        name => $title.' - episode '. $_->{episodeNumber},
        url  => $self->url.'read/mepisode/'.$_->{manga_id}.'/'.$_->{episodeNumber}
    } } @$json;

    return @results;
}

#-------[ HOSTS LIST ]---------------------------------------------------------
# Here the last link is saved in the params variable
# So the controller don't records it
#
sub _get_emission_hosts_list {
    my ( $self, $dom ) = @_;
    my ( $id, $u, $tx, $json, @results );
    my @hosts = qw(mystream openload uptostream okru);

    $id = $dom->at('.chooseEpisodeEmission')->attr('data-id');
    $u =  $self->url.'read/episode/'.$id.'/1';

    $tx = $self->ua->get( $u );
    return () unless $tx->success;
    $dom = html_unescape( $tx->res->dom );
    $json = decode_json( $dom );
    $json = $json->{episode};

    $u = $self->url.'streamerEpisode/1/'.$id.'/';

    foreach my $h ( @hosts ) {
        if( defined $json->{$h} and $json->{$h} ne "" ) {
            push( @results, {
                name   => $h,
                url    => $self->url,
                params => $u.$h, 
            } );
        }
    }

    return @results;
}

sub _get_manga_hosts_list {
    my ( $self, $dom ) = @_;
    my ( $json, $id, $ep, $u, @results );
    my @hosts = qw(okru mystream openload okru_vostfr mystream_vostfr openload_vostfr); 

    $dom = html_unescape( $dom );
    $json = decode_json( $dom );
    $json = $json->{episode};

    $id = $json->{manga_id};
    $ep = $json->{episodeNumber};
    $u = $self->url.'streamerMEpisode/'.$ep.'/'.$id.'/';

    foreach my $h ( @hosts ) {
        if ( defined $json->{$h} and $json->{$h} ne "" ) {
            push( @results, {
                name   => $h,
                url    => $self->url,
                params => $u.$h,
            } );
        }
    }

    return @results;
}

sub _get_hosts_list {
    my ( $self, $dom ) = @_;
    
    my @results = $dom->find('.lecteurs a')
        ->map( sub { [
            trim( $_->all_text ),
            $_->attr('data-v-on') =~ s/.*select(\w+)/lcfirst($1)/er,
            $_->attr('data-id'),
            $_->attr('data-streamer'),
        ] } )
        ->map( sub { {
            name    => $$_[3] =~ /vostfr/?$$_[0].' - VOSTFR':$$_[0].' - VF',
            url     => $self->url,
            params  => $self->url.$$_[1].'/'.$$_[2].'/'.$$_[3],
        } } )
        ->each;
    
    return @results;
}

#-------[ RESOLVER ]-----------------------------------------------------------
#
sub _get_host_url {
    my ( $self, $dom ) = @_;
    my ( $json, @result );

    $dom = html_unescape( $dom );
    $dom =~ s/["\']code["\']\s*:/"url":/;
    $dom =~ s/["\']streamer["\']\s*:/"name":/;
    $json = decode_json( $dom );
    push @result, $json;
    
    return @result;
}

#-------[ NEXT PAGE ]----------------------------------------------------------
#
sub _find_next_page {
    my ( $self, $dom ) = @_;
    my @result;

    $dom = $dom->at('ul.pagination li.active');
    return () unless $dom;
    $dom = $dom->next;
    return () unless $dom;
    $dom = $dom->at('a');
    return () unless $dom;

    push( @result, { 
        url => $dom->attr('href'),
        name => '>> page '. $dom->text,
    } );
    
    return @result;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

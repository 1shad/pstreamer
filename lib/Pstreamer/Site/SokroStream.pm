package Pstreamer::Site::SokroStream;

=head1 NAME

 Pstreamer::Site::SokroStream

=cut

use utf8;
use Mojo::URL;
use Mojo::Util qw(encode url_escape);
use Mojo::JSON 'decode_json';
use Moo;

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

has '+url' => ( default => 'http://sokrostream.tv/' );

has '+menu' => ( default => sub { {
    'Accueil' => '/',
    'Films'   => '/categories/films-streaming',
    'Series'  => '/categories/series-streaming',
} } );

#_______/ GET RESULTS \______________________________________________
sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, @results);

    return () unless defined $tx;
    $dom = $tx->result->dom;

    for ( $tx->req->url ) {
        if   ( /search\//  ) {
            @results = $self->_get_search( $dom );
        }
        elsif( /categories\//){
            @results = $self->_get_categories( $dom );
        }
        elsif(     /films\/[^\/]+\.html/ 
                or /series\/[^\/]+saison[^\/]+episode[^\/]+\.html/ ) {
            @results = $self->_get_hosts( $dom );
        }
        elsif( /series\/[^\/]+saison[^\/]+\.html/ ) {
            @results = $self->_get_episodes( $dom );
        }
        elsif( /series\/[^\/]+\.html/ ) {
            @results = $self->_get_seasons( $dom );
        }
        else {
            @results = $self->_get_home( $dom );
        }
    }
    return @results;
}

#_______/ SEARCH \___________________________________________________
sub search {
    my ( $self, $text ) = @_;
    my ( $headers, $surl, $tx );
    
    $headers = { Referer => $self->url };
    $surl    = $self->_make_absolute( "/search/".url_escape( $text ) );
    $tx      = $self->ua->get( $surl => $headers );

    return $tx;
}

#_______/ GET HOME \__________________________________________________
# get results from home page
sub _get_home {
    my ( $self, $dom )= @_;
    my ( $temp, @results );
    
    my $datas = $self->_get_datas( $dom );

    foreach my $t ( qw(films series) ) {
        foreach my $e ( qw(nouveaux box) ) {
            $temp = $datas->{$e}->{$t};
            push @results, $self->_generate_results( $temp, $t );
        }
    }
    
    push @results, $self->_next_page( $dom );
    return @results;
}

#_______/ GET HOSTS \________________________________________________
# Extract hosts video links
sub _get_hosts {
    my ( $self, $dom ) = @_;
    my ( $datas, $ep, $name, $videos, @results );

    $datas = $self->_get_datas( $dom );
    
    $ep  = "";
    $ep .= "s".$datas->{season}  if exists( $datas->{season}  );
    $ep .= "e".$datas->{episode} if exists( $datas->{episode} );

    $datas = $datas->{data};
    $name  = $datas->{name};
    
    $datas  = $datas->{episode}->[0] if exists( $datas->{episode} );
    $videos = $datas->{videos};

    foreach my $e ( @{$videos} ) {
        my $n = join( ' - ', grep{ $_ }
            ($name, $ep, $e->{quality}, $e->{language}, $e->{provider})
        );
        push( @results, { name => $n, url => $e->{link} } );
    }

    return @results;
}

#_______/ GET SEASONS \______________________________________________
# Extract seasons links
sub _get_seasons {
    my ( $self, $dom ) = @_;
    my ( $datas, $name, $qual, @results );

    $datas = $self->_get_datas( $dom );
    $name  = $datas->{data}->{name};
    $qual  = $datas->{data}->{quality};
    
    @results = $dom->find('.box .is-3 a button')
        ->map( sub{ {
            name => join(' - ', $name, $_->text, $qual),
            url  => $self->_make_absolute($_->parent->attr('href'))
        } } )
        ->each;
    
    return @results;
}

#_______/ GET EPISODES \_____________________________________________
# Extract episodes links
sub _get_episodes {
    my ( $self, $dom ) = @_;
    my ( $datas, $name, $season, $qual, @results );

    $datas  = $self->_get_datas( $dom );
    $season = "Saison " . $datas->{season};
    $name   = $datas->{data}->{name};
    $qual   = $datas->{data}->{quality};

    @results = $dom->find('.box .is-3 a button')
        ->grep( sub { $_->text =~ /Episode/ } )
        ->map( sub { {
            name => join(' - ', $name , $season, $_->text, $qual ),
            url  => $self->_make_absolute($_->parent->attr('href')),
        } } )
        ->each;

    return @results;
}

#_______/ GET CATEGORIES \___________________________________________
# Extract links in categories pages
sub _get_categories {
    my ( $self, $dom ) = @_;
    my ( $datas, $type, @results );

    $datas = $self->_get_datas( $dom );
    $datas = $datas->{elements};

    # try to find the type of elements ( films or series )
    foreach my $e ( @{$datas} ) {
        $type = "films"  if ( $e->{poster} =~ /films/  );
        $type = "series" if ( $e->{poster} =~ /series/ );
        last if $type; # stop first time it is found
    }

    push @results, $self->_generate_results( $datas, $type );
    push @results, $self->_next_page( $dom );

    return @results;
}

#_______/ GET SEARCH \_______________________________________________
# Extract links from search results
sub _get_search {
    my ( $self, $dom ) = @_;
    my ( $datas, @results );

    $datas = $self->_get_datas( $dom );

    foreach my $t ( qw(films series) ) {
        push @results, $self->_generate_results( $datas->{$t}, $t );
    }

    return @results;
}

#_______/ GENERATE RESULTS \_________________________________________
# Generate the final array required by the ui.
sub _generate_results {
    my ( $self, $array, $type ) = @_;
    my @results;
    
    foreach ( @{$array} ) {
        my $name = $self->_generate_name( $_, $type );
        my $url  = $self->_generate_url( $_, $type );
        push( @results, { url => $url, name => $name } ); 
    }

    return @results;
}

#_______/ GET DATAS \________________________________________________
# Extract vue.js datas from html source
sub _get_datas {
    my ( $self, $html ) = @_;

    my ($datas) = $html =~ /window\.__NUXT__=(.*?);<\/script>/;
    return unless $datas;

    $datas = encode( 'utf-8', $datas );
    $datas = decode_json( $datas );

    return $datas->{'data'}->[0];
}

#_______/ GENERATE URL  \____________________________________________
# Generate url from a data element with a defined type
# ( type => series(tv shows) or films )
sub _generate_url {
    my ( $self, $e, $type ) = @_;
    return "" unless $e;

    my $url = $e->{name};
    
    $url =~ s/[ëèéê]/e/g;
    $url =~ s/[âäà]/a/g;
    $url =~ s/[ùûü]/u/g;
    $url =~ s/[öô]/o/g;
    $url =~ s/[ïî]/i/g;
    $url =~ s/ç/c/g;
    $url =~ s/[#!&:,]//g;
    $url =~ s/\s+$//;
    $url =~ s/[\'\/%]|\s+/-/g;
    $url = "/$type/".lc($url)."-".$e->{customID}.".html";
    
    $url = $self->_make_absolute( $url );
    return $url;
}

#_______/ GENERATE NAME \____________________________________________
# Generate the name displayed by the ui from a data element
sub _generate_name {
    my ( $self, $e, $type ) = @_;
    return "" unless $e;

    my $name = $e->{name}." - ".uc($e->{language})." - ".uc($e->{quality});

    if ( $type ) {
        my $c = substr( $type, 0, 1 );
        $name = '('.uc($c).') '.$name;
    }

    return $name;
}

#_______/ MAKE ABSOLUTE \____________________________________________
# return absolute url
sub _make_absolute {
    my ( $self, $u ) = @_;
    return Mojo::URL->new($u)->to_abs($self->url)->to_string;
}

#_______/ NEXT PAGE \________________________________________________
# Find the next page link if any
sub _next_page {
    my ( $self, $dom ) = @_;
    my ( $next, @result );

    $next = $dom->at('.pagination-link.is-current');
    return () unless $next;

    $next = $next->parent->next();
    return () unless $next;

    $next = $next->at('a');
    return () unless $next;
    
    push( @result, {
        name => ">> page ".$next->text,
        url  => $self->_make_absolute( $next->attr('href') ),
    });

    return @result;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


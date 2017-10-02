package Pstreamer::Site::ZoneTelechargement;

=head1 NAME

 Pstreamer::Site::ZoneTelechargement

=cut

use utf8;
use Mojo::Util 'trim';
use Mojo::URL;
use Moo;

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

has '+url' => ( default => 'https://www.zone-telechargement.ws/' );

has '+menu' => ( default => sub { {
    'Accueil'             => '/',
    'Exclus'              => '/exclus/',
    'Films-DVDRiP'        => '/films-dvdrip-bdrip/',
    'Films-DVDRiP-mkv'    => '/films-mkv/',
    'Films-VOSTFR'        => '/filmsenvostfr/',
    'Films-x265-x264'     => '/x265-x264-hdlight/',
    'Films-Vieux'         => '/vieux-films/',
    'Films-Mangas'        => '/films-mangas/',
    'Dessins-animes'      => '/dessins-animes/',
    'Series-VF'           => '/series-vf/',
    'Series-VF-720p'      => '/series-vf-en-hd/',
    'Series-VF-1080p'     => '/series-vf-1080p/',
    'Series-VOSTFR'       => '/series-vostfr/',
    'Series-VOSTFR-720p'  => '/series-vostfr-hd/',
    'Series-VOSTFR-1080p' => '/series-vostfr-1080p/',
    'Series-VO'           => '/series-vo/',
    'Animes-VF'           => 'animes-vf',
    'Animes-VOSTFR'       => 'animes-vostfr',
    'Animes-OAV'          => '/oav/',
    'Emissions-TV'        => 'emissions-tv',
} } );

sub search {
    my ( $self, $text ) = @_;
    return $self->ua->post( $self->url.'index.php?do=search' => form => {
        story     => $text,
        do        => 'search',
        subaction => 'search',
    } );
}

# Gets results 
sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, $url, @results );

    if ( $self->params ) {
        my $params = $self->params;
        $self->params( undef );
        return $self->_Qaptcha_bypass( $params ) ;
    }
    
    $url = $tx->req->url;
    $dom = $tx->result->dom;

    for ( $url ) {
        if ( /\.html$/ ) {
            @results = $self->_get_links( $dom );
        }
        else {
            @results = $self->_get_default_results( $dom );
        }
    }

    return @results;
}

# extracts links and title infos
sub _get_default_results {
    my ( $self, $dom ) = @_;
    my @results;

    @results = $dom->find('.cover_global')
        ->map( 'find', '.cover_infos_title>a, span>b' ) 
        ->map( sub { {
            url  => $$_[0]->attr('href'),
            name => join ' - ', map { trim( $_->all_text ) } @{$_},
        } } )
        ->grep( sub { $_->{url} !~ /\/jeux\// } )
        ->each;

    push( @results, $self->_find_next($dom) );
    return @results;
}

# extract video links
sub _get_links {
    my ( $self, $dom ) = @_;
    my ( @others, @results );

    @others = $dom->find( '.otherversions a' )
        ->map( sub { {
            name => "Autre version disponible >> ". $_->all_text,
            url  => Mojo::URL->new( $_->attr('href') )->to_abs($self->url),
        } } )
        ->each;

    @results = $dom->find('.postinfo a')
        ->grep( sub {
            $_->attr('href') =~ /123455600123455602123455610123455615/ 
            and $_->text !~ /partie/i 
        } )
        ->map( sub { {
            params => $_->attr('href') =~ s/\r//gr,
            url    => $self->url,
            name   => 'Uptostream - '. $_->text =~ s/T.*er/Regarder/r,
        }})
        ->each;

    push ( @results, @others );

    return @results;
}

# find next if any
sub _find_next {
    my ( $self, $dom ) = @_;
    my @result;

    $dom = $dom->at('.navigation > a:last-child');
    return () unless $dom and $dom->text eq "Suivant";
    return () if $dom->attr('href') eq "#";
    
    push( @result, { 
        url => $dom->attr('href'),
        name => '>>'.$dom->attr('href') =~ s/.*\/page\/(.*)\// page $1/r,
    } );

    return @result;
}

#_______/ Qaptcha \__________________________________________________
#
# Bypass Qaptcha
sub _Qaptcha_bypass {
    my ( $self, $url ) = @_;
    my ( $tx, $headers, $key, $url2, @result );

    ## ROUND 1
    # drag bar
    $url2 = 'https://www.protect-lien.com/php/Qaptcha.jquery.php';

    $headers = {
        Referer => $url,
        Accept  => 'application/json, text/javascript, */*; q=0.01',
        'X-Requested-With' => 'XMLHttpRequest',
        'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
    };

    $key = _Qaptcha_generate_pass();

    $tx = $self->ua->post( $url2 => $headers => form => {
        action => 'qaptcha',
        qaptcha_key => $key,
    });

    return () unless $tx->success;
    
    # ROUND 2
    # submit button
    $headers = {
        Referer => $url,
        'Content-type' => 'multipart/form-data'
    };

    $tx = $self->ua->post( $url => $headers => form => {
        $key => '',
        submit => 'Valider',
    });

    return () unless $tx->success;

    my $dom = $tx->res->dom->at('.lienet > a');
    return () unless $dom;
    
    push ( @result, {
        name => 'uptostream',
        url  => $dom->attr('href') =~ s/uptobox/uptostream/r,
    });
    
    return @result;
}

# generate a random pass
sub _Qaptcha_generate_pass {
    my ( $res, @s );
    
    @s = split //,"azertyupqsdfghjkmwxcvbn23456789AZERTYUPQSDFGHJKMWXCVBN_-#@";
    $res = join( '', map { $s[ int(rand(58)) ] } 1 .. 32 );
    return $res;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


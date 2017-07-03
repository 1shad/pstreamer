package Pstreamer::Site::Skstream;

=head1 NAME

 Pstreamer::Site::Skstream

=cut

use Mojo::URL;
use Mojo::Util 'trim';
use Mojo::JSON 'decode_json';
use Moo;

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

has '+url' => ( default => 'http://www.skstream.co/' );

has '+menu' => ( default => sub { {
    'Accueil' => '/',
    'Films'   => '/films',
    'Series'  => '/series',
    'Mangas'  => '/mangas',
} } );

sub search {
    my ( $self, $text ) = @_;
    return $self->ua->get( $self->url.'recherche' => form => { s => $text } );
}

sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, @results );
    
    $dom = $tx->result->dom;
    
    for ( $tx->req->url ) {
        if ( /episode|films.+/ and !/\/page\// ) {
            @results = $self->_get_hosters_links( $dom, $_ );
        }
        elsif ( /(#.+)$/ ) {
            @results = $self->_get_episodes( $dom, $1 );
        }
        elsif ( /series.+|mangas.+/ ) {
            @results = $self->_get_seasons( $dom, $_ );
        }
        else {
            @results = $self->_get_default( $dom );
        }
    }
    
    return @results;
}

sub _get_default {
    my ( $self, $dom ) = @_;

    my @results = $dom->find('a.unfilm > div.title')
        ->map( sub { {
            url  => Mojo::URL->new($_->parent->attr('href'))
                        ->to_abs($self->url)->to_string,
            name => $_->all_text,
        } } )
        ->each;
    
    push( @results, $self->_find_next_page($dom) );
    return @results;
}

sub _get_episodes {
    my ( $self, $dom, $item ) = @_;
    my ( $node, @results );

    $node = $dom->at($item)->parent->parent->parent;
    @results = $node->find('a')
        ->map( sub { {
            url  => Mojo::URL->new($_->attr('href'))->to_abs($self->url),
            name => $_->attr('title') =~ s/\sen\sstreaming|regarder\s//gir,
        } } )
        ->each;
    
    return @results;
}


sub _get_seasons {
    my ( $self, $dom, $uri ) = @_;
    my ( $title, @results );

    $title = $dom->at('p:first-of-type')->text;

    @results = $dom->find('div.panel:nth-child(2) a')
        ->map( sub { { 
            url => $uri.$_->attr('href'),
            name => $title.' - '.$_->text,
        } } )
        ->each;
    
    return @results;
}

sub _get_hosters_links {
    my ( $self, $dom, $uri ) = @_;
    my ( $headers, @results );

    $headers = { Referer => $uri };

    @results = $dom->find('tr.changeplayer')
        ->map('find', 'td')
        ->map( sub { {
            url  => $_->[0]->parent->attr('data-embedlien'),
            name => join ' ', map { 
                trim( $_->all_text ) 
            } ( $_->[1], $_->[2], $_->[3] ),
        } } )
        ->each;
    
    # get urls from dl-protect
    $|++; print "dl-protect, patience...\r";
    
    @results = map {
        if ( $_->{url} =~ /dl-protect/ ) {
            @{ $self->_get_dl_protect( $_, $headers ) };
        } else { $_ }
    } @results;

    print ' 'x30 ."\r"; $|--;
    #@results = grep { $_->{url} } @results;

    return @results;
}

sub _get_dl_protect {
    my ( $self, $item, $headers ) = @_;
    my ( $tx , $res );

    $res = [];

    $tx = $self->ua->head( $item->{url} => $headers );
    
    # Case redirect
    if ( $tx->res->code == 301 or $tx->res->code == 302 ) {
        $res = [ {
            url  => $tx->res->headers->header('location'),
            name => $item->{name},
        } ];
    }
    else {
        $tx = $self->ua->get( $item->{url} => $headers );
        # case iframe
        if ( my $iframe = $tx->res->dom->at('iframe') ) {
            my $src = Mojo::URL->new( $iframe->attr('src') );
            $res = [ {
                url => $src->host('drive.google.com'),
                name => $item->{name},
            } ];
        }
        # case jwplayer ( not a host so stream => 1 )
        elsif ( my ($json) = $tx->res->dom =~ /sources:\s?(\[.*?\]),/ ) {
            $json = decode_json( $json );
            $res = [ map { {
                url    => $_->{file},
                name   => $item->{name}.' ('.$_->{type}.','.$_->{label}.'p)',
                stream => 1,
            } } @$json ];

        }
        else {
            warn 'unknown method dl-protect';
        }
    }

    return $res;
}

sub _find_next_page {
    my ( $self, $dom ) = @_;
    my @result;

    $dom = $dom->at('ul.pagination > li.active');
    return () unless $dom;
    $dom = $dom->next->at('a');
    return () unless $dom;

    push( @result, { 
        url => Mojo::URL->new($dom->attr('href'))->to_abs($self->url),
        name => '>> page '.$dom->text, 
    } );
    
    return @result;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


package Pstreamer::Site::Radego;

=head1 NAME

 Pstreamer::Site::Radego

=cut

use Mojo::Util qw(trim);
use Mojo::JSON 'decode_json';
use Mojo::URL;
use Moo;

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

has '+url' => (
    default => 'http://radego.com/cxcxds0iklm454vc54bfd87gdfs8/',
);

has '+menu' => ( default => sub { {
    'Accueil'       => '/',
    'A l\'affiche'  => '/index.php?option=com_content&view=category&id=29&Itemid=7',
    'Animation'     => '/index.php?option=com_content&view=category&id=2&Itemid=2',
    'Documentaires' => '/index.php?option=com_content&view=category&id=26&Itemid=4',
    'Spectacle'     => '/index.php?option=com_content&view=category&id=3&Itemid=5',
} } );

sub search {
    my ( $self, $text ) = @_;
    my $tx;

    my $form = {
        Itemid => 0,
        option => 'com_search',
        task => 'search',
        searchword => $text,
    };

    $self->ua->max_redirects(1);
    $tx = $self->ua->post( $self->url.'index.php' => form => $form );
    $self->ua->max_redirects(0);

    return $tx;
}

sub get_results {
    my ( $self, $tx ) = @_;
    my ( @results );

    for ( $tx->req->url ) {
        if ( /\?searchword/ ) {
            @results = $self->_get_search_results($tx->res->dom);
        } elsif ( /&view=article/ ) {
            @results = $self->_get_article_results($tx->res->dom, $_);
        } else {
            @results = $self->_get_default_results($tx->res->dom);
        }
    }

    return @results;
}

sub _get_default_results {
    my ( $self, $dom ) = @_;
    my ( @results );

    @results = $dom->find('span[style="list-style-type:none;"] a')
        ->map( sub { {
            url => Mojo::URL->new($_->attr('href'))->to_abs($self->url),
            name => trim($_->all_text)
        } } )
        ->each;

    push( @results, $self->_find_next_page($dom) );
    return @results;
}

sub _get_article_results {
    my ( $self, $dom, $url ) = @_;
    my ( $headers, $html, $title, $json, $tx, $temp, @results );

    # get title name
    $title = $dom->at('.contentheading>span');
    $title = $title ? trim($title->text) : 'Google';
    # get iframe src
    $url = $dom->at('iframe')->attr('src');

    # get iframe content
    $headers = { Referer => $url };
    $url = Mojo::URL->new($url)->to_abs($self->url);
    $tx = $self->ua->get($url => $headers);

    # get the first link url in the iframe and get its content
    $temp = $tx->res->dom->at('a')->attr('href');
    $url = Mojo::URL->new($temp)->to_abs($url);
    $tx = $self->ua->get($url => $headers);

    # prepare the html document and get the sources links
    $html = $tx->res->dom =~ s/[\n\s\t\r]//gr;
    # get and decode json sources
    ($json) = $html =~ /sources:\s?(\[.*?\]),/;
    return () unless $json;
    # prepare json string
    $json =~ s/(file|label|type)/"$1"/g;
    $json =~ s/'/"/g;
    $json =~ s/,(}|])/$1/g;
    # decode
    $json = decode_json( $json );
    # filter
    $json = [ grep{ $_->{file} ne "" } @{$json} ];

    # resolve the last redirection link from each sources
    for ( @{$json} ) {
        $headers = { Referer => $url };
        while (1) {
            $tx = $self->ua->head( $_->{file} => $headers);
            last unless ( $tx->res->code == 302 or $tx->res->code == 301 );
            $headers = { Referer => $_->{file} };
            $_->{file} = $tx->res->headers->header('location');
        }
    }

    # Parse and return results
    # files are played directly
    @results = map { {
        url    => $_->{file},
        name   => join( ' - ', $title, $_->{type}, $_->{label} ),
        stream => 1,
    } } @{$json};

    return @results;
}

sub _get_search_results {
    my ( $self, $dom ) = @_;
    my ( @results );

    @results = $dom->find('.results a')
        ->map( sub { {
            url => Mojo::URL->new($_->attr('href'))->to_abs($self->url),
            name => trim($_->all_text)
        } } )
        ->each;

    return @results;
}

sub _find_next_page {
    my ( $self, $dom ) = @_;
    my @result;

    $dom = $dom->at('.pagination  a[title="Suivant"]');
    return () unless $dom;
    push( @result, {
        url => Mojo::URL->new($dom->attr('href'))->to_abs($self->url),
        name => '>> page suivante' },
    );

    return @result;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

package Pstreamer::Site::Seriestreamhd;

=head1 NAME

 Pstreamer::Site::Seriestreamhd

=cut

use utf8;
use Mojo::Util 'trim';
use Moo;

with 'Pstreamer::Role::Site','Pstreamer::Role::UA';

has '+url' => ( default => 'http://ww2.serie-streaminghd.com/' );

has '+menu' => ( default => sub { {
    'Accueil'            => '/',
    'Serie VF'           => '/regarder-series/vf-hd/',
    'Serie VOSTFR'       => '/regarder-series/vostfr-hd/',
    'Top Series'         => '/top-serie/',
    'Saison Complete'    => '/saison-complete/',
}});

sub search {
    my ( $self, $text ) = @_;
    my $headers = { Referer => $self->url };

    $self->ua->post( $self->url => $headers => form => {
        story     => $text,
        subaction => 'search',
        do        => 'search',
    });
}

# Dispatch
sub get_results {
    my ( $self, $tx ) = @_;
    my ( $dom, $url, @results );
    
    $dom = $tx->result->dom;

    for ( $tx->req->url ) {
        if ( /\.html$/) {
            @results = $self->_get_hosts($dom);
        } else {
            @results = $self->_get_links($dom);
        }
    }
    
    return @results;
}

# Les liens vers les hebergeurs des episodes 
sub _get_hosts {
    my ( $self, $dom ) = @_;
    my ( $title, @results);

    $title = trim($dom->at('h4.title-name')->text);
    $title =~ s/\sen\sstreaming//i;

    @results = $dom->find('.elink a')
        ->map( sub {
              my $lang = trim($_->parent->previous->text);
              my $text = trim($_->all_text) =~ s/EPS/Episode/r;
              {
                  url => $_->attr('href'),
                  name => join( ' - ', $title, $text, $lang )
              }
         })
        ->each;
}

# Les liens vers les series sur les différentes pages
sub _get_links {
    my ( $self, $dom ) = @_;
    my ( @results );

    @results = $dom->find('h3.mov-title a')
        ->map( sub { { 
            url  => $_->attr('href'),
            name => $_->text,
        } } )
        ->each;
    push( @results, $self->_next_page($dom) );
    return @results;
}

# Le lien vers la page suivante s'il existe
sub _next_page {
    my ( $self, $dom ) = @_;
    my ( $name, @results );

    $dom = $dom->at('div.navigation > a:last-child');
    return unless $dom;
    return unless $dom->text =~ /Suivant/;

    $name = $dom->attr('href') =~ s/.*(page)\/(\d+)\/$/>>> $1 $2/r;

    push @results, { url => $dom->attr('href'), name => $name };
    return @results;   
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

package Pstreamer::Host::Cloudy;

=head1 NAME

 Pstreamer::Host::Cloudy

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $id, $title, @results );

    $id = $self->_get_id_from_url( $url );
    $url = 'http://www.cloudy.ec/v/'.$id;
    
    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    
    $title = $tx->res->dom->at('h4.title');
    $title = $title->text if $title;

    $tx = $self->ua->get( 'http://www.cloudy.ec/embed.php'
        => form => { id => $id, playerPage => 1 }
    );
    return 0 unless $tx->success;

    @results = $tx->res->dom->find('source')
        ->map( sub { { 
            url    => $_->attr('src'), 
            name   => $_->attr('type'),
            title  => $title,
            stream => 1
        } } )
        ->grep( sub { $_->{url} } )
        ->each;

    return @results?\@results:0;
}

sub _get_id_from_url {
    my ( $self, $url ) = @_;
    
    my @t = reverse split /\//, $url;
    $t[0] =~ s/&\w+=\d//g;
    $t[0] =~ s/embed.php\?id=//;

    return $t[0];
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

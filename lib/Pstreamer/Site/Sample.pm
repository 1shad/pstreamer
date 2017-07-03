package Pstreamer::Site::Sample;

=head1 NAME

 Pstreamer::Site::Sample

=head1 DESCRIPTION

 Sample file, to start writing a new one

=cut

use Moo;

with 'Pstreamer::Role::Site', 'Pstreamer::Role::UA';

has '+url' => ( default => '/sample.test' );

has '+menu' => ( default => sub { {
    'Home' => '/',
} } );

sub search {
    my ( $self, $text ) = @_;
    my $tx;

    $tx = $self->ua->get( $self->url => form => { q => $text } );

    return $tx;
}

sub get_results {
    my ( $self, $tx ) = @_;
    my ( @results );
    
    for ( $tx->req->url ) {
        if ( /\?q=.*/ ) { 
            @results = $self->_get_search_results($tx->res->dom);
        } else {
            @results = $self->_get_default_results($tx->res->dom);
        }
    }

    return @results;
}

sub _get_default_results {
    my ( $self, $dom ) = @_;
    my ( @results );

    @results = ( {
        url  => '/sample.test/page',
        name => 'default',
    } );

    push( @results, $self->_find_next_page($dom) );
    return @results;
}

sub _get_search_results {
    my ( $self, $dom ) = @_;
    my ( @results );
    
    @results = ( {
        url  => '/sample.test/page',
        name => 'search',
    } );

    return @results;
}

sub _find_next_page {
    my ( $self, $dom ) = @_;
    my @result;

    push( @result, { 
        url => '/sample.test/next',
        name => 'next' },
    );

    return @result;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

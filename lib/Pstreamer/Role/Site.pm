package Pstreamer::Role::Site;

=head1 NAME

 Pstreamer::Role::Site

=cut

use Mojo::URL;
use Moo::Role;

requires qw(search get_results);

has params => ( is => 'rw', default => undef );

has url => (
    is => 'rw',
    default => '/',
    coerce => sub {
        my $url = shift;
        $url ? Mojo::URL->new( $url ) : undef ;
    },
    trigger => 1, 
);

has menu => (
    is => 'ro',
    default => sub { { Home => '/' } },
    coerce => sub {
        my $menu = shift;
        return undef unless $menu;
        return [ map { {
            name => $_,
            url  => Mojo::URL->new( $menu->{$_} ),
        } } sort keys %{$menu} ];
    },
);

# populate the menu urls.
sub _trigger_url {
    my ( $self, $url ) = @_;
    return undef unless $url and $url->is_abs;
    
    foreach my $menu ( @{$self->menu} ) {
        if ( ! $menu->{url}->is_abs and @{$url->path->parts} ) {
            $menu->{url}->path->merge( $url->path );
        }
        $menu->{url} = $menu->{url}->to_abs( $url );
        $menu->{url} = $menu->{url}->scheme( $url->scheme );
        $menu->{url} = $menu->{url}->host( $url->host );
    }
    return 1;
}

# need it one time after object creation
sub _init {
    my $self = shift;
    $self->_trigger_url( $self->url );
    return $self;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


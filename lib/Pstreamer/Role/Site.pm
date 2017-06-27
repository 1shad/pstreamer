package Pstreamer::Role::Site;

=head1 NAME

 Pstreamer::Role::Site

=cut

use Mojo::URL;
use Pstreamer::Config;
use Moo::Role;

has params => ( is => 'rw', default => undef );

requires qw(url menu search get_results);

sub BUILD {
    my ( $self ) = @_;
    
    $self->{url} = Mojo::URL->new( $self->{url} );
    
    my $menu = $self->{menu};
    $self->{menu} = [ map { {
        name => $_,
        url  => Mojo::URL->new($menu->{$_})->to_abs($self->url),
    } } sort keys %{$menu} ];

}

1;

=head1 TODO

 Don't use BUILD ...

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


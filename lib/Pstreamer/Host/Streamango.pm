package Pstreamer::Host::Streamango;

=head1 NAME

 Pstreamer::Host::Streamango

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ( $dom, $file );

    $dom = $self->ua->get( $url )->result->dom;
    
    ($file) = $dom =~ /{type:"video\/mp4",src:"([^"]+)",/;
    if ($file) {
        return $file = [{
            url => 'https:'.$file,
            stream => 1,
        }];
    } else {
        return 0;
    }
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


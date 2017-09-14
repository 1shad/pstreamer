package Pstreamer::Host::Vidto;

=head1 NAME

 Pstreamer::Host::Vidto

=cut

use Pstreamer::Util::Unpacker 'jsunpack';
use Moo;

with 'Pstreamer::Role::UA', 'Pstreamer::Role::UI';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $dom, $file, $params, $js );
    
    $url = $self->_set_url( $url );
    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    $dom = $tx->res->dom;
    
    $params = { $dom->find('form[method="POST"] input')
        ->map( sub { { $_->attr('name') => $_->attr('value') } } )
        ->each
    };
    $params->{referer} = $url;
    
    $self->wait_for(6, 'Patientez:'); # 6s needed 
    $tx = $self->ua->post( $url => form => $params );
    return 0 unless $tx->success;
    $dom = $tx->res->dom;

    ($js) = $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\))\n?<\/script>/;
    
    if ($js) {
        $js = jsunpack( \$js );
        return 0 unless $js;
        ($file) = $js =~ /,\{?file:"([^"]+)"}/;
        ($file) = $js =~ /{file:\s*"([^"]+(?<!smil))"}/ if ! $file;
    } else {
        ($file) = $dom =~ /{file:"([^"]+)",label:"(\d+p)"}/;
        ($file) = $dom =~ /{file:\s*"([^"]+(?<!smil))"}/ if ! $file;
    }
    
    return $file?$file:0;
}

sub _set_url {
    my ( $self, $url ) = @_;
    $url =~ s/embed-([^-.]+).*/$1/;
    return $url;
}

1;

=head1 DESCRIPTION

 Handles Vidto and Vidtodo. Actually Vidto seems down.

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/vidto.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


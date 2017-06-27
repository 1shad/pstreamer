package Pstreamer::Host::Vidto;

=head1 NAME

 Pstreamer::Host::Vidto

=cut

use Pstreamer::Util::Unpacker;
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ($dom, $file, $params, $js );
    
    $url = $self->_set_url( $url );
    $dom = $self->ua->get( $url )->result->dom;
    
    $params = { $dom->find('form[method="POST"] input')
        ->map( sub { { $_->attr('name') => $_->attr('value') } } )
        ->each
    };
    $params->{referer} = $url;
    
    $self->_wait(6); # 6s needed 
    $dom = $self->ua->post( $url => form => $params )->result->dom;
    ($js) = $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\))\n?<\/script>/;
    
    if ($js) {
        print "-- javascrit found --\nurl: $url\n";
        $js = Pstreamer::Util::Unpacker->new( packed => \$js )->unpack;
        ($file) = $js =~ /,file:"([^"]+)"}/;
    } else {
        ($file) = $dom =~ /{file:"([^"]+)",label:"(\d+p)"}/;
    }
    
    return $file?$file:0;
}

sub _set_url {
    my ( $self, $url ) = @_;
    $url =~ s/embed-([^-]+).*/$1/;
    return $url;
}

sub _wait {
    my ( $self, $s ) = @_;
    $|++;
    while ( $s > 0 ) {
        print "patientez: ".$s--."s\r";
        sleep(1);
    }
    print "\n";
    $|--;
}

1;

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/vidto.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


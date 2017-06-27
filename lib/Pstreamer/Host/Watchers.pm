package Pstreamer::Host::Watchers;

=head1 NAME

 Pstreamer::Host::Watchers

=cut

use Pstreamer::Util::Unpacker;
use Moo;

with 'Pstreamer::Role::UA';

sub get_filename{
    my ($self, $url) = @_;
    my ( $dom, $js, $headers, @results );

    $dom = $self->ua->get( $url )->result->dom;
    ($js) = $dom =~ /(eval\(function\(p,a,c,k,e(?:.|\s)+?\))\n?<\/script>/;
    return 0 unless $js;
    $js = Pstreamer::Util::Unpacker->new ( packed => \$js )->unpack;
    
    $headers.='|Referer=http://watchers.to/player7/jwplayer.flash.swf';
    while( $js =~ /{file:"([^"]+)",label:"(\d+)"}/g ){
        push( @results, {
            url  => $1.$headers,
            name => $2,
            stream => 1,
        });
    }

    return @results?\@results:0;
}

1;

=head1 INSPIRED BY

 L<https://github.com/Kodi-vStream/venom-xbmc-addons/blob/Beta/plugin.video.vstream/resources/hosters/watchers.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


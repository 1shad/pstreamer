package Pstreamer::Host::GoogleDrive;

=head1 NAME

 Pstreamer::Host::GoogleDrive

=cut

use Mojo::Util 'url_unescape';
use Moo;

with 'Pstreamer::Role::UA','Pstreamer::Role::UI';

my %FORMATS = (
    '5'  => 'flv',
    '6'  => 'flv',
    '13' => '3gp',
    '17' => '3gp',
    '18' => 'mp4',
    '22' => 'mp4',
    '34' => 'flv',
    '35' => 'flv',
    '36' => '3gp',
    '37' => 'mp4',
    '38' => 'mp4',
    '43' => 'webm',
    '44' => 'webm',
    '45' => 'webm',
    '46' => 'webm',
    '59' => 'mp4',
);

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $files, $cookies, $fmt_stream_map, $fmt_list );

    $url = $self->_set_url($url);

    $tx = $self->ua->get($url);
    return 0 unless $tx->success;

    if ( $tx->res->dom =~ /"reason"\s*,\s*"([^"]+)/ ) {
        $self->error($1);
        return 0;
    }

    # save cookies
    $_ = $tx->res->headers->header('set-cookie');
    $cookies = '';
    while ( $_ and /(?:^|,) *([^;,]+?)=([^;,\/]+?);/g ) {
        $cookies .= "$1=$2;";
    }
    
    # get datas
    ($fmt_stream_map) = $tx->res->dom
        =~ /"fmt_stream_map"\s*,\s*"([^"]+)/;

    ($fmt_list) = $tx->res->dom
        =~ /"fmt_list"\s*,\s*"([^"]+)/;

    # The file doesn't exist
    return 0 unless $fmt_stream_map;
    
    # format datas
    $fmt_stream_map = { map {
        my @t = split /\|/, $_;
        $t[1] =~ s/\\u(....)/ pack 'U*', hex($1) /eg;
        $t[1] = url_unescape( $t[1] );
        $t[0] => $cookies? $t[1].'|cookie='.$cookies : $t[1];
    } split /,/, $fmt_stream_map };

    $files = [ map {
        my @t = split /\//, $_;
        {
            url    => $fmt_stream_map->{ $t[0] },
            name   => $t[1].' - '.$FORMATS{ $t[0] },
            stream => 1,
        }
    } split /,/, $fmt_list ];
    
    return $files;
}

sub _set_url {
    my ( $self, $url ) = @_;
    
    if ( $url =~ /docid=([\w-]+)/ ) {
        $url = 'https://drive.google.com/file/d/'.$1.'/view';
    }
    
    $url =~ s/preview/view/;
    return $url;
}

1;

=head1 INSPIRED BY

 L<https://github.com/rg3/youtube-dl/blob/master/youtube_dl/extractor/googledrive.py>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


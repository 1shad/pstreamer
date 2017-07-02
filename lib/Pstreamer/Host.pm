package Pstreamer::Host;

=head1 NAME

Pstreamer::Host

=cut

use Class::Inspector;
use Carp 'confess';
use Moo;


########################################
# The name must match the url host name 
#
my %hosters = (
    # name         => 'PackageName';
    'sample.test'  => 'Pstreamer::Host::Sample',
    easyvid        => 'Pstreamer::Host::Easyvid',
    vidup          => 'Pstreamer::Host::Vidup',
    vidto          => 'Pstreamer::Host::Vidto',
    uptostream     => 'Pstreamer::Host::Uptostream',
    nowvideo       => 'Pstreamer::Host::Nowvideo',
    watchers       => 'Pstreamer::Host::Watchers',
    cloudy         => 'Pstreamer::Host::Cloudy',
    'streamin.to'  => 'Pstreamer::Host::Streamin',
    'ok.ru'        => 'Pstreamer::Host::Okru',
    'vidlox.tv'    => 'Pstreamer::Host::Vidlox',
    'estream.to'   => 'Pstreamer::Host::Estream',
    'speedvid.'    => 'Pstreamer::Host::Speedvid',
    streamango     => 'Pstreamer::Host::Streamango',
    mystream       => 'Pstreamer::Host::Mystream',
    itazar         => 'Pstreamer::Host::Itazar',
    openload       => 'Pstreamer::Host::Openload',
    vidoza         => 'Pstreamer::Host::Vidoza',
    vidabc         => 'Pstreamer::Host::Vidabc',
    'drive.google' => 'Pstreamer::Host::GoogleDrive',
    hqq            => 'Pstreamer::Host::Netu',
);

########################################
# Choose the host via the url.
# Loads the package unless it is loaded.
# Returns the created object,
# or undef if the host is not found.
#
sub _get_host {
    my ( $self, $url ) = @_;
    my $host = undef;
    
    return undef unless defined $url;

    for my $key ( keys %hosters ) {
        $host = $hosters{$key} if $url =~ /\Q$key\E/;
    }
    
    return undef unless defined $host;

    unless ( Class::Inspector->loaded( $host ) ) {
        eval "require $host";
        confess $@ if $@;
    }

    $host = $host->new;

    return $host;
}

########################################
# Calls the host get_filename
# and returns its value.
# Returns undef if no host.
#
sub get_filename {
    my ( $self, $url ) = @_;
    my $host = undef ;

    $host = $self->_get_host($url);
    
    #print "$url\n" unless defined $host;
    return defined $host ? $host->get_filename($url) : undef ;
}

1;

=head1 DESCRIPTION

 A factory class.

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

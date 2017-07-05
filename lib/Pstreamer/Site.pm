package Pstreamer::Site;

=head1 NAME

Pstreamer::Site

=cut

use Carp qw(confess);
use Class::Inspector;
use Moo;

my %sites = (
    # name => "PackageName",
    sample              => "Pstreamer::Site::Sample",
    streaming_series_cx => "Pstreamer::Site::StreamingSeriescx",
    sokrostream         => "Pstreamer::Site::SokroStream",
    librestream         => "Pstreamer::Site::LibreStream",
    Radego              => "Pstreamer::Site::Radego",
    papystreaming       => "Pstreamer::Site::PapyStreaming",
    skstream            => "Pstreamer::Site::Skstream",
);

###########################
# current: the site object
# it selects the package via the name as parameter
has current => (
    is => 'rw',
    default => undef,
    coerce => sub {
        my $current = shift;
        return undef unless defined $current and defined $sites{$current};
        unless ( Class::Inspector->loaded( $sites{$current} ) ) {
            eval "require $sites{$current}";
            confess $@ if $@;
        }
        $sites{$current}->new->_init;
    },
    handles => 'Pstreamer::Role::Site',
);

###########################
# Returns the list of current sites
sub get_sites {
    my $self = shift;
    my @results = ();
    for my $site (sort keys %sites ){
        next if $site eq 'sample';
        my %result;
        $result{name} = $site;
        $result{url} = "PICO";
        push @results, \%result;
    }
    return @results;
}

1;

=head1 DESCRIPTION

 A factory class.

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

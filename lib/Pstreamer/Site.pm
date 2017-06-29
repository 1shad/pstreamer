package Pstreamer::Site;

=head1 NAME

Pstreamer::Site

=cut

use Carp qw(confess);
use Class::Inspector;
use Moo;

my %sites = (
    # name => "PackageName",
    streaming_series_cx => "Pstreamer::Site::StreamingSeriescx",
    sokrostream => "Pstreamer::Site::SokroStream",
    librestream => "Pstreamer::Site::LibreStream",
    Radego => "Pstreamer::Site::Radego",
    papystreaming => "Pstreamer::Site::PapyStreaming",
    skstream => "Pstreamer::Site::Skstream",
);

###########################
# current: the site object
# it selects the package via the name as parameter
has current => (
    is => 'rw',
    default => undef,
    coerce => sub {
        my $current = shift;
        return undef unless defined $current;
        unless ( Class::Inspector->loaded( $sites{$current} ) ) {
            eval "require $sites{$current}";
            confess $@ if $@;
        }
        return $sites{$current}->new;
    },
);

###########################
# Returns an array of hashes with names
# used by current to select the package
sub get_sites {
    my $self = shift;
    my @results = ();
    for my $site (sort keys %sites ){
        my %result;
        $result{name} = $site;
        $result{url} = "PICO";
        push @results, \%result;
    }
    return @results;
}

###########################
# Fonctions defined in
# Pstreamer::Site::Packages
###########################
sub url {
    my $self = shift;
    return "" unless defined $self->current;
    return $self->current->url;
}

sub menu {
    my $self = shift;
    return () unless defined $self->current;
    return $self->current->menu;
}

sub search {
    my ( $self, $text ) = @_;
    return () unless defined $self->current;
    return $self->current->search($text);
}

sub get_results {
    my ( $self, $tx ) = @_;
    return () unless defined $self->current;
    return () unless $tx;
    return $self->current->get_results( $tx );
}

sub params {
    my ( $self, $params ) = @_;
    return 0 unless defined $self->current;
    return $self->current->params($params);
}

1;

=head1 DESCRIPTION

 A kind of factory class

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

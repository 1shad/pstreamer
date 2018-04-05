package Pstreamer::Host::Openload;

=head1 NAME

 Pstreamer::Host::Openload

=cut

use Mojo::DOM;
use Class::Inspector;
use IPC::Cmd 'can_run';
use Moo;

with 'Pstreamer::Role::UA','Pstreamer::Role::UI';

around get_filename => sub {
    my $origin = shift;
    my ( $self ) = @_;
    my $phantom = 'WWW::Mechanize::PhantomJS';

    unless( Class::Inspector->loaded( $phantom ) ) {
        eval "require $phantom";
        if ( $@ ) {
            $self->error("$phantom requis");
            return undef;
        }
    }

    unless( can_run('phantomjs') ) {
        $self->error("Ne peut pas executer phantomjs");
        return undef;
    }

    return $origin->( @_ );
};

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $dom, $file, $id, $mech );

    $url = $self->_set_url($url);

    $self->status("PhantomJS en cours");
    $mech = WWW::Mechanize::PhantomJS->new();
    $mech->eval_in_phantomjs(<<'JS1', $self->ua->transactor->name);
        var page = this;
        page.settings.userAgent = arguments[0];
        page.viewportSize = { width: 1920, height: 1080 };
        page.onInitialized = function() {
            page.evaluate(function() {
                delete window._mech;
                delete window._phantom;
                delete window.callPhantom;
            });
        };
JS1

    $mech->get($url);
    $dom = Mojo::DOM->new( $mech->content );

    # Il est possible de trouver l'id via cette regex, puis de rechercher
    # dans la page l'élément avec cet id.
    # snippet:
    # ($id) = $dom =~ /#realdl\sa.*?attr.*?stream.*?#([^'"]+)/;
    # $id = $dom->at('#'.$id);

    # Sinon rechercher directement l'élément via les selecteurs css
    $id = $dom->at('div[style="display:none;"] > p:first-child + p:last-child');
    return 0 unless $id;

    # - ancien code -
    # foreach ( ('#streamurl', '#streamuri', '#streamurj') ) {
    #     $id = $dom->at( $_ ) and last if $dom->at( $_ );
    # }
    # return 0 unless $id;

    $file = 'https://openload.co/stream/'.$id->text.'?mime=true';
    return $file;
}

sub _set_url {
    my ( $self, $url ) = @_;
    my ($id) = $url =~ /https?:\/\/(?:openload\.(?:co|io)|oload\.tv)\/(?:f|embed)\/([\w\-]+)/;
    #$url = 'https://openload.co/embed/'. $id . '/';
    $url = 'https://openload.co/f/'. $id . '/';
    return $url;
}

1;

=head1 INSPIRED BY

 L<https://gist.github.com/Tithen-Firion/8b3921d745131837519d5c5b95b86440>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


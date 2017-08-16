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
    my ( $dom, $file, $mech );
    
    $self->status("PhantomJS en cours");
    $mech = WWW::Mechanize::PhantomJS->new;
    $mech->eval_in_phantomjs(<<'JS1', $self->ua->transactor->name);
        var page = this;
        page.settings.userAgent = arguments[0];
        page.viewportSize = { width: 1680, height: 1050 };
        page.onInitialized = function() {
            page.evaluate(function() {
                delete window._mech;
                delete window.callPhantom;
            });
        };
JS1
    
    $url = $self->_set_url($url);
    
    $mech->get($url);

    $dom = Mojo::DOM->new( $mech->content );
    $file = $dom->at('#streamurl');
    return 0 unless $file;
    
    $file = 'https://openload.co/stream/'.$file->text.'?mime=true';

    return $file;
}

sub _set_url {
    my ( $self, $url ) = @_;
    my ($id) = $url =~ /https?:\/\/(?:openload\.(?:co|io)|oload\.tv)\/(?:f|embed)\/([\w\-]+)/;
    $url = 'https://openload.co/embed/'. $id . '/';
    return $url;
}

1;

=head1 INSPIRED BY

 L<https://gist.github.com/Tithen-Firion/8b3921d745131837519d5c5b95b86440>

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


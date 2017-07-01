package Pstreamer::App;

=encoding utf8

=head1 NAME

Pstreamer::App - Streaming with perl 

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';

use utf8;
use feature 'say';
use Try::Tiny;
use Term::ANSIColor 'colored';
use Scalar::Util qw(looks_like_number refaddr);
use Pstreamer::Util::CloudFlare;
use Pstreamer::Viewer;
use Pstreamer::Host;
use Pstreamer::Site;
use Pstreamer::Config;
use Moo;
use MooX::Options description => 'perldoc Pstreamer::App pour les détails';

has [qw(config ua tx stash term viewer host site cf command history)] => (
    is => 'rw',
    default => undef,
);

option go => (
    is => 'ro',
    format => 's@',
    default => sub { [] },
    autosplit => ',',
    doc => "Automate, ex: --go=2,'ma serie'",
);

option fullscreen => (
    is => 'ro',
    short => 'fs',
    negatable => 1,
    doc => 'Videos en plein ecran',
);

option version => (
    is => 'ro',
    short => 'v',
    doc => 'Affiche la version',
);

sub BUILD {
    my $self = shift;
    $self->_init;
}

sub _init {
    my $self = shift;

    my %options = (
        fullscreen => $self->fullscreen,
    );

    defined $options{$_} or delete $options{$_} for keys %options;

    $self->config( Pstreamer::Config->instance( %options  ) );
    $self->viewer( Pstreamer::Viewer->new );
    $self->host( Pstreamer::Host->new );
    $self->site( Pstreamer::Site->new );
    $self->cf( Pstreamer::Util::CloudFlare->new );
    $self->ua( $self->config->ua );
    $self->term( $self->config->term );
    $self->history( [] ); # LIFO
    $self->command( [qw(:q :s :p :m)] );
    $self->term->addhistory( $_ ) for @{$self->command};
}

sub run {
    my $self = shift;
    my ( @choices, @tmp, $line );

    if ( $self->version ) {
        say "\nThis is pstreamer version $VERSION\n";
        exit;
    }

    while ( 1 ) {
        my $count = 0;

        @choices = $self->site->get_sites unless $self->site->current;

        # if only one host or stream url, it doesn't show the menu
        if ( @choices == 1 && ! $self->_is_internal( $choices[0]->{url} ) ){
            $line = 0;
        }
        elsif ( @{$self->go} ) {
            $line = shift @{$self->go};
            if ( $line eq 'print') {
                $self->_print_choices( @choices ) if $line eq 'print';
                $line = shift @{$self->go} // ':q';
            }
        }
        else { # get user input

            for ( @choices ) {
                say ($count>9?"":" ",colored($count++ ,'bold'),": ",$_->{name});
            }
            if ( $self->stash ) {
                say colored( $self->stash, 'red' );
                $self->stash(undef);
            }
            $line = $self->term->readline(colored(">>> ", 'bold'));
        }
        
        # proceed user input
        next unless defined $line and $line ne "";

        if ( $self->_is_command( $line ) ) {
            @tmp = $self->_proceed_command( $line );
        }
        elsif ( looks_like_number($line) && $line < @choices ) {
            @tmp = $self->_proceed_line( $choices[$line] );
        }
        else {
            @tmp = $self->_proceed_search($line);
        }
        $self->stash( 'Aucun résultat') unless @tmp;
        @choices = @tmp if @tmp;
    }
}

sub _print_choices {
    my ( $self, @choices ) = @_;
    my $count = 0;

    foreach  ( @choices ) {
        say ($count>9?"":" ",colored($count++ ,'bold'),": ",$_->{name});
    }
}


sub _proceed_command {
    my ( $self, $line ) = @_;
    my ( $previous, @choices );

    exit if $line eq ":q";

    if ( $line eq ":s" ) {
        @choices = $self->site->get_sites;
    }
    elsif ( $line eq ":m" ) {
        return undef unless $self->site->current;
        @choices = @{$self->site->menu};
    }
    elsif ( $line eq ":p"){
        $previous = $self->_get_history;
        return $self->site->current(undef) unless $previous;
        $self->tx( $self->_get($previous) );
        @choices = $self->site->get_results($self->tx);
    }
    return @choices;
}

sub _proceed_line {
    my ( $self, $element ) = @_;
    my @choices;

    for( $element ) {
        if( $_->{url} =~ /^PICO$/ ) { # site choice
            $self->site->current( $_->{name} );
            $self->tx( $self->_get( $self->site->url ) );
        }
        elsif ( $self->_is_internal( $_->{url} ) ) { # site internal
            if ( defined $_->{params} ) {
                $self->site->current->params($_->{params});
            } else {
                $self->_add_history( $self->tx->req->url );
                $self->tx( $self->_get( $_->{url} ) );
            }
        }
        elsif ( defined $_->{stream} ) { # stream file
            $self->viewer->stream( $_->{url}, $_->{stream} );
        }
        else { # host urls
            my $res;
            try {
                $res = $self->_proceed_host( $_->{url} );
            } catch {
                warn $_ ;
            };
            return @{$res} if $res;
        }
    }

    try { @choices = $self->site->get_results($self->tx); }
    catch { warn $_ ; };
    return @choices;
}

sub _proceed_host {
    my ( $self, $url ) = @_;
    my $res = $self->host->get_filename( $_->{url} );

    if ( $res and !refaddr( $res ) ) {
        $res = [{ url => $res, stream => 1 }];
    }
    elsif ( $res and refaddr( $res ) ) {
        $res = $res;
    }
    elsif ( !$res and defined $res ) { # = 0
        $self->stash('Fichier introuvable');
    }
    elsif( !defined $res ) { # = undef
        $self->stash("Ce lecteur n'est pas supporté");
    }
    return $res;
}

sub _proceed_search {
    my ( $self, $line ) = @_;
    my @choices;

    $self->_add_history( $self->tx->req->url ) if $self->tx;
    $self->tx( $self->site->search($line) );
    @choices = $self->site->get_results($self->tx);

    return @choices;
}

sub _get {
    my ( $self, $url ) = @_;
    my $tx;
    
    try {
        $tx = $self->ua->get( $url );
        $tx = $self->cf->bypass if $self->cf->is_active( $tx );
    } catch {
        warn ( $_ );
    };
    
    return $tx;
}

sub _is_command {
    my ( $self, $line ) = @_;
    my $commands = join '|', @{$self->command};
    return  $line =~ /^($commands)$/;
}

sub _is_internal {
    my $self = shift;
    my $link = shift;
    my $host;

    # case 1: no site is active
    return 0 unless $self->site->current;

    # case 2: link is not internal. ie: host or stream file
    $host = $self->site->url->host;
    return 0 unless $link =~ /\Q$host/;

    return 1;
}

sub _add_history {
    my ( $self, $e ) = @_;
    unshift @{$self->history}, $e;
}

sub _get_history {
    my $self = shift;
    my $e = shift @{$self->history};
    return $e;
}

1;

=head1 DESCRIPTION

 Pstreamer permet de visionner des films ou des series,
 en streaming, depuis un terminal. Il fonctionne sous GNU/Linux.

 Il se connecte à certains sites français. Perrmet de parcourir le site
 via les liens disponibles ou par son menu, et permet de faire des recherches.
 Les vidéos sont lues depuis les hebergeurs avec mpv.

=head1 UTILISATION
 
 Pour lancer pstreamer, executer:
 $ pstreamer

 Le programme affiche les liens avec des numeros en début de ligne.
 Taper le numero de la ligne pour aller à la page suivante ou alors
 écrire un texte pour lancer une recherche.

 Les commandes du prompt disponibles sont:
  :p pour précédent
  :m pour afficher le menu du site
  :s pour afficher les sites
  :q pour quitter

=head1 OPTIONS

=head2 --fullscreen|--fs

    Lance mpv en plein ecran.
    
=head2 --go
    
    pstreamer est capable d'automatiser les entrées.
    
    Avec cette option, vous pouvez aller directement à la page
    voulue, si vous connaissez d'avance les numéros et les textes
    que vous auriez écrit en lancant le programme.

    exemple1: pstreamer  --go=2,'ma série'
        permet de sélectionner le 3eme site, puis
        de faire une recherche avec le texte 'ma série'.
        pstream affiche les résultats, puis le prompt.

    exemple2: pstreamer --fs --go=2,'ma serie',2,1,0,0,:q
        pstreamer lance automatiquement l'épisode avec 
        mpv en plein ecran. Il quitte juste apres mpv.

    exemple3: pstreamer --go=2,'ma serie',2,2,0,0,:p,1,0,:q
        enchaine automatiquement les deux premiers épisodes
        de 'ma serie' puis quitte.
    
    Pour aller plus loin:
        'print' permet d'afficher les résultats.
        
        Si vous entrez: --go=2,'ma serie',:q
        le programme quitte mais n'affiche rien.

        Il faut alors entrer: --go=2,'ma serie',print
        pstream affiche les résultats puis quitte.
        
        Si il n'y a rien derrière print le programme quitte,
        sinon il continue avec ce qui suit.
        
=head1 INSTALLATION

 Pour installer pstreamer, exécuter:
    
    git clone https://github.com/1shad/pstreamer.git
    cd pstreamer
    perl Makefile.PL
    make
    make install

=head1 DOCUMENTATION

 Après installation, vous pouvez trouver la documentation avec la commande:
    perldoc Pstream::App

=head1 DEPENDENCES

=head2 Modules perl requis:

=over

=item Moo

=item utf8::all

=item Mojolicious

=item WWW::Mechanize::PhantomJS

=item MooX::Singleton

=item MooX::Options

=item MooX::ConfigFromFile

=item Class::Inspector

=item Term::ANSIColor

=item Term::ReadLine::Gnu

=item Scalar::Util

=item File::Spec

=item File::HomeDir

=item Config::Tiny

=item Try::Tiny

=back

=head2 Programmes externes requis:

=over

=item mpv, L<https://mpv.io/>

=item phantomjs, L<http://phantomjs.org/>

=back

 Pour phantomjs, il est recommandé de télécharger la version depuis le site
 plutôt que de l'installer avec votre gestionnaire de paquets. Et ensuite,
 faites en sorte que l'exécutable soit dans votre PATH.

=head1 BUGS

Veuillez signaler tout bugs ou demandes de fonctionnalités via l'interface Web:
L<https://github.com/1shad/pstreamer/issues>.
Je serai informé, et vous serez automatiquement informé de l'avancement.

Please report any bugs or feature requests through the web interface at:
L<https://github.com/1shad/pstreamer/issues>.
I will be notified, and then you'll automatically be notified of progress
on your bugs as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 1shad.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

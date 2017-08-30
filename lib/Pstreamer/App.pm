package Pstreamer::App;

=encoding utf8

=head1 NAME

Pstreamer::App - Application de streaming vidéo

=head1 VERSION

 Version 0.008

=cut

our $VERSION = '0.008';

use utf8;
use feature 'say';
use Try::Tiny;
use Scalar::Util qw(refaddr reftype);
use Pstreamer::Config;
use Pstreamer::Util::CloudFlare;
use Pstreamer::Viewer;
use Pstreamer::Host;
use Pstreamer::Site;
use Moo;
use MooX::Options description => 'perldoc Pstreamer::App pour les détails';

option ncurses => (
    is          => 'rw',
    negativable => 1,
    doc         => "Active l'interface ncurses",
);

option gtk => (
    is          => 'rw',
    negativable => 1,
    doc         => "Active l'interface Gtk",
);

option fullscreen => (
    is          => 'ro',
    short       => 'fs',
    negativable => 1,
    doc         => 'Videos en plein ecran',
);

option go => (
    is        => 'ro',
    format    => 's@',
    default   => sub { [] },
    autosplit => ',',
    doc       => "Automate, ex: --go=2,'ma serie'",
);

option version => (
    is    => 'ro',
    short => 'v',
    doc   => 'Affiche la version',
);

has [qw(config ua tx viewer host site cf UI)] => (
    is => 'rw',
);

# LIFO
has history => (
    is      => 'ro',
    default => sub { [] },
);

around history => sub {
    my $origin = shift;
    my $self = shift;
    return shift @{$self->$origin} unless @_;
    unshift( @{$self->$origin}, grep { defined } reverse @_ );
    return $self->$origin;
};

before run => sub { shift->_init };

# creates objects and vars
sub _init {
    my $self = shift;
    
    # catch all warnings
    $SIG{__WARN__} = sub { return 1; };
    
    $self->gtk(0) if !$self->gtk and $self->ncurses;

    if ( @{$self->go} ) {
        $self->ncurses(0);
        $self->gtk(0);
    }

    my %options = (
        fullscreen => $self->fullscreen,
        ncurses    => $self->ncurses,
        gtk        => $self->gtk,  
    );

    defined $options{$_} or delete $options{$_} for keys %options;

    $self->config( Pstreamer::Config->instance( %options  ) );
    $self->viewer( Pstreamer::Viewer->new );
    $self->host( Pstreamer::Host->new );
    $self->site( Pstreamer::Site->new );
    $self->cf( Pstreamer::Util::CloudFlare->new );
    $self->ua( $self->config->ua );
    $self->UI( $self->config->ui );
}

sub run {
    my $self = shift;

    if ( $self->version ) {
        say "\nThis is Pstreamer::App version $VERSION\n";
        exit;
    }

    $self->UI->init;
    $self->UI->controller( $self );
    $self->UI->site_list( [$self->site->get_sites] );
    # start with the list of sites
    $self->UI->list( [$self->site->get_sites] );
    $self->UI->run;
}

sub proceed {
    my ( $self, $element ) = @_;
    my $one_choice_str = '';
    return unless $element;
    
    my @list = $self->_proceed_line( $element );
    
    while ( @list == 1 and ! $self->_is_internal( $list[0]->{url} ) ) {
        # breaks recursion if any
        if ( $one_choice_str =~ /$list[0]->{url}/ ) {
            @list = $self->UI->list;
            last;
        } else {
            $one_choice_str .= $list[0]->{url};
        }
        @list = $self->_proceed_line( $list[0] );
    }
    
    $self->UI->error('Aucun résultat') unless @list;
    $self->UI->list( [@list] );
}

sub proceed_previous {
    my $self = shift;
    my @list;

    my $previous = $self->history;

    unless ( $previous ) {
        $self->UI->list( [$self->site->get_sites] );
        $self->UI->site_name( undef );
        $self->UI->menu_list( undef );
        $self->site->current( undef );
        return;
    }
    
    $self->tx( $self->_get( $previous ) );
    @list = $self->site->get_results( $self->tx );
    $self->UI->list( [@list] );
}

# processes search text written by the user
sub proceed_search {
    my ( $self, $text ) = @_;
    my @list;
    return unless $self->site->current;
    return unless $text and $text ne "";

    $self->history( $self->tx->req->url ) if $self->tx;
    $self->tx( $self->site->search($text) );
    @list = $self->site->get_results($self->tx);
    
    $self->UI->error('Aucun résultat') unless @list;
    $self->UI->list( [@list] );
}

# processes the selected line by the user
sub _proceed_line {
    my ( $self, $element ) = @_;
    my @choices;

    return undef unless $element 
        and refaddr( $element )
        and reftype( $element ) eq reftype {}
        and $element->{url};
    
    for( $element ) {
        if( $_->{url} =~ /^PICO$/ ) { # site choice
            $self->site->current( $_->{name} );
            $self->UI->site_name( $_->{name} );
            $self->UI->menu_list( $self->site->menu );
            # it needs to follow redirects here
            $self->ua->max_redirects(5);
            $self->tx( $self->_get( $self->site->url ) );
            $self->ua->max_redirects(0);
            # set in case url has changed
            if ( $self->site->url ne $self->tx->req->url ) {
                $self->site->url( $self->tx->req->url );
            }
        }
        elsif ( $self->_is_internal( $_->{url} ) ) { # site internal
            if ( defined $_->{params} ) {
                $self->site->current->params($_->{params});
            } else {
                $self->history( $self->tx->req->url );
                $self->tx( $self->_get( $_->{url} ) );
            }
        }
        elsif ( defined $_->{stream} ) { # stream file
            try   { $self->viewer->stream( $_->{url}, $_->{stream} ); }
            catch { $self->UI->error("Le lien trouvé n'est pas valide"); };
        }
        else { # host urls
            my $res;
            try   { $res = $self->_proceed_host( $_->{url} );}
            catch { $self->UI->error( $_ ); };
            return @{$res} if $res;
        }
    }

    try { @choices = $self->site->get_results($self->tx); }
    catch { $self->UI->error( $_ ); };
    return @choices;
}

# processes hosts urls
sub _proceed_host {
    my ( $self, $url ) = @_;
    return undef unless $url;
    
    my $res = $self->host->get_filename( $url );

    if ( $res and !refaddr( $res ) ) {
        $res = [{ url => $res, stream => 1 }];
    }
    elsif ( $res and refaddr( $res ) ) {
        $res = $res; # ...
    }
    elsif ( !$res and defined $res ) { # = 0
        $self->UI->error('Fichier introuvable');
    }
    elsif( !defined $res ) { # = undef
        $self->UI->error("Ce lecteur n'est pas supporté");
    }
    return $res;
}

# get url with Mojo::UserAgent and bypass cloudflare IMUA if it is active
sub _get {
    my ( $self, $url ) = @_;
    my $tx;
    
    try {
        $tx = $self->ua->get( $url );
        $tx = $self->cf->bypass if $self->cf->is_active( $tx );
    } catch {
        $self->UI->error( $_ );
    };
    
    return $tx;
}

# Returns true or false if link is internal to the site or not
sub _is_internal {
    my $self = shift;
    my $link = shift;
    my $host;

    # case 1: no site active
    return 0 unless $self->site->current;

    # case 2: link is not internal. ie: host or stream file
    $host = $self->site->url->host;
    return 0 unless $link =~ /\Q$host/;

    return 1;
}

1;

=head1 DESCRIPTION

Pstreamer permet de visionner des films ou des series,  
en streaming, depuis un terminal, sur un système compatible Unix.

Il se connecte à certains sites français. Permet de les parcourir  
via les liens disponibles ou par son menu, et permet de faire des recherches.  
Les vidéos sont lues depuis les hébergeurs avec mpv.

=head1 UTILISATION

Pour lancer pstreamer, exécutez:

    $ pstreamer

=head1 INTERFACES

Il y a trois interfaces disponibles: 'text', 'ncurses', et 'gtk3'.  
L'interface text est utilisée par défault.

=head2 TEXT

Le programme affiche les liens avec des numéros en début de ligne.  
Taper le numéro de la ligne puis entrée pour continuer ou alors  
écrire un texte pour lancer une recherche.

Les commandes du prompt disponibles sont:

    :p précédent
    :m afficher le menu du site
    :s afficher les sites
    :q quitter
    :h aide  

=head2 NCURSES

Le programme affiche les liens disponibles. Selectionner le lien  
en descendant ou en montant avec les flèches haut et bas du clavier,  
ou avec les touches 'k' et 'j', puis valider avec soit la touche entrée,  
fleche droite ou 'l'.  
Les touches flèche gauche ou 'h' permettent de revenir à la page précédente.  

Voici la liste des racourcis:

    'j', 'bas'    : descendre dans la liste
    'k', 'haut'   : monter dans la liste
    'h', 'gauche' : précédent
    'l', 'droite' : suivant

    's' : menu selection d'un site
    'm' : menu du site (inactif si aucun site n'est selectionné)
    '>' : recherche

    Control-q : quitter

=head2 GTK3

Cette interface ressemble à celle en ncurses et s'utilise de la même manière.  
Par contre, il y a moins de racourcis. Ils seront ( peut-être ) rajoutés plus tard.  

Le menu déroulant de gauche affiche la selection des sites.  
Le menu déroulant de droite affiche le menu du site selectionné.  
Quand il n'y a pas encore de site selectionné, le menu de droite est inactif.  

Le bouton Recherche affiche l'entrée de texte. Tapez un texte à l'interieur  
puis Entrée pour lancer votre recherche.

Dans la liste, cliquez sur la ligne voulue pour la selectionner.  
Sinon utilisez les flèches du clavier haut et bas pour aller sur la ligne voulue,  
puis Entrée ou Flèche droite pour la selectionner.

Le bouton Retour ou Flèche gauche servent à revenir en arrière dans la liste.

Control-q pour quitter ou cliquez sur la croix.

La priorité est sur cette interface sur vous activez les deux options sur la ligne  
de commande ou dans le fichier de configuration.

=head1 OPTIONS

Les options de la ligne de commande sont prioritaires  
par rapport à celles du fichier de configuration.

=head2 --version|-v

Affiche la version.

=head2 --fullscreen|--fs

Lance mpv en plein écran. Désactivée par défault.

=head2 --no-fullscreen

Désactive le plein écran, si l'option est activée dans  
le fichier de configuration.

=head2 --ncurses

Active l'interface ncurses

=head2 --no-ncurses

Désactive l'interface ncurses si l'option est activée  
dans le fichier de configuration.

=head2 --gtk

Active l'interface Gtk

=head2 --no-gtk

Désactive l'interface Gtk si l'option est activée  
dans le fichier de configuration

=head2 --go

Cette option n'est disponible que avec l'interface text,  
donc cette interface est automatiquement utilisée avec.

Elle permet d'automatiser les entrées.  
Le programme etant un 'bot', elle est utile pour réaliser des  
scripts ou des alias pour faire des bookmarks.  
Vous trouverez un exemple de script à la fin de cette section.

Les commandes utilisées sont celles de l'interface text, plus  
la commande 'print'.

Donc au lieu d'entrer dans le programme,  
puis taper 2,Entrée,'ma serie',Entrée,0,Entrée

Vous pouvez écrire: 

    $ pstreamer --go=2,'ma série',0


Si vous souhaitez juste afficher les résultats, pour vérifier  
qu'un épisode est disponible ou autre, il faut utiliser la commande 'print'.

exemple:

    $ pstreamer --go=2,'ma serie',2,1,print


Le programme affiche les résultats puis quitte.  
Si vous utilisez la commande ':q', le programme  
n'affichera pas les résultats, donc il faut remplacer ':q'  
par 'print'.

Si il n'y a rien derrière print le programme quitte,  
sinon il continue avec ce qui suit.

Voici un petit script bash à lancer avec la crontab  
qui permet d'alerter l'utilisateur qu'un épisode est  
disponible:

    #!/usr/bin/env bash
    export DISPLAY=:0.0         # requis pour notify-send
    export PATH=$HOME/bin:$PATH # selon votre installation

    # a omettre ou adapter selon votre installation de perl    
    export PERL5LIB=$HOME/localperl/lib/perl5

    # Comme je fais souvent un 'ls' dans mon repertoire home
    # je ne peux pas le louper, et ca évite d'avoir plusieurs
    # fois la nofitication.
    if [ -f $HOME/MYSCRIPT.lock ]; then
        exit 0;
    fi

    res=$(pstreamer --go=3,'game of',0,6,print|grep 'Episode 4'|wc -l)

    if [ $res -gt 0 ]; then
        notify-send "Episode dispo"
        touch $HOME/MYSCRIPT.lock
    fi

C'est, bien sur, complètement inutile mais si besoin,  
adaptez selon votre recherche et votre installation.

=head1 CONFIGURATION

Vous pouvez utiliser un fichier de configuration, si vous  
le souhaitez, pour paramétrer quelques propriétés ou options.

Le format du fichier est libre, mais dépends d'un certain module.  
Installez un des modules de la liste pour utiliser le format voulu.

La liste des formats:

    - Yaml (.yaml|.yml) :
            YAML, YAML::XS, YAML::Syck
    - Json (.json|.jsn) :
            JSON, Cpanel::JSON::XS, JSON::MaybeXS, JSON::XS, JSON::Syck ...
    - Xml (.xml) :
            XML::Simple
    - Conf ( .conf|.cnf )
            Config::General
    - INI ( .ini )
            Config::Tiny

Le nom du fichier doit être 'config' avec l'extension qui vous plait.  

Par exemple:

    config.ini

Le fichier de configuration doit être placé dans un des répertoires suivant:

    $HOME/.pstreamer/
    $HOME/.config/pstreamer/

Les options actuellement disponibles sont:

    fullscreen: 0 ou 1
    cookies: 0 ou 1
    user_agent: texte
    ncurses: 0 ou 1
    gtk: 0 ou 1

Exemple d'un fichier INI:

    # config.ini
    user_agent = Mozilla/5.0 (X11; Linux) AppleWebKit/538.15...
    fullscreen = 1
    cookies = 1
    ncurses = 1

Note pour les cookies:  
Pstreamer utilisera un fichier pour stocker les cookies si  
vous activer l'option.  
C'est utile pour cloudflare IMUA, mais pas encore optimisé.  
Donc l'option n'est pas disponible pour la ligne de commande.  

L'emplacement du fichier est pour l'instant:

    $HOME/.config/pstreamer/cookies/

=head1 DEPENDENCES

=head2 Modules perl requis:

=over

=item Moo

=item utf8::all

=item Mojolicious

=item IO::Socket::SSL

=item MooX::Singleton

=item MooX::Options

=item MooX::ConfigFromFile

=item Class::Inspector

=item Term::ReadLine::Gnu

=item File::HomeDir

=item Data::Record

=item Regexp::Common

=item Try::Tiny

=item Curses::UI

=item Gtk3

=back

=head2 Modules perl recommandés:

=over

=item WWW::Mechanize::PhantomJS

=item Config::Tiny

=back

=head2 Programme externe requis:

=over

=item mpv, L<https://mpv.io/>

=back

=head2 Programme externe recommandé:

=over

=item phantomjs, L<http://phantomjs.org/>

=back

=head1 INSTALLATION

Pour installer pstreamer, exécutez:

    $ git clone https://github.com/1shad/pstreamer.git
    $ cd pstreamer

Si vous avez une installation locale de perl.  
Vous pouvez installer depuis le répertoire en utilisant cpanm,  
qui installera aussi les dépendances :

    $ cpanm .

Sinon, installez les dépendances, avec par exemple pour debian :

    $ apt-get install libmoo-perl libutf8-all-perl libmojolicious-perl \
    libio-socket-ssl-perl libmoox-singleton-perl libmoox-options-perl \
    libmoox-configfromfile-perl libclass-inspector-perl libfile-homedir-perl \
    libtry-tiny-perl libdata-record-perl libregexp-common-perl \
    libterm-readline-gnu-perl libconfig-tiny-perl libcurses-ui-perl libgtk3-perl

Et ensuite depuis le répertoire :

    $ perl Makefile.PL
    $ make
    $ make test
    $ sudo make install

NB:  
* Les librairies suivantes sont requises si vous compilez vos modules avec cpanm *   
( Celles-ci sont disponibles pour GNU/Debian. Le nom d'un paquet peut être différent  
en fonction de votre système )
Veuillez installer ces librairies avant d'installer ces modules.

Pour Curses: libncursesw5-dev  
( utilisation de l'utf-8)  

Pour Gtk3:  
libglib2.0-dev ( Glib )  
libcairo2-dev  ( Cairo )  
libgirepository1.0-dev  ( Glib::Object::Introspection )

=head1 MISES A JOUR

Si vous avez gardé le répertoire d'installation du dessus :

    $ cd /chemin/pstreamer
    $ git pull

Ensuite comme pour l'installation :

    $ cpanm .
    ou
    $ Perl Makefile.PL
    $ make && make test
    $ sudo make install

Si vous n'avez pas gardé le répertoire :

    Comme pour l'installation sans les dépendances.

=head1 INSTALLATION DE WWW::Mechanize::PhantomJS

Phantomjs n'est utilisé que pour l'hebergeur openload.  
Comme il n'y a pas de paquet pour l'installer il faut le faire avec cpanm.

Si vous souhaitez l'installer, voilà la procédure :

Installez Object::Import :

    $ cpanm Object::Import

Ca échoue,  
Alors comme indiqué dans ce patch:  
L<http://cpan.cpantesters.org/authors/id/S/SR/SREZIC/patches/Object-Import-1.004-RT106769.patch>  
Il faut modifier un fichier: 

    $ cd ~/.cpanm/latest-build/Object-Import-1.004

Editez le fichier t/04_handle.t avec par exemple:

    $ vim t/04_handle.t

et remplacez la ligne 10 (qui utilise une vieille syntaxe) par:  

    my($TT, $tn) = tempfile(UNLINK => 1);  

sauvegardez puis installez le depuis ce répertoire:

    $ cpanm .
    $ cd

Ensuite installez le module :

    $ cpanm WWW::Mechanize::PhantomJS

Puis le programme phantomjs, depuis le site ou avec votre gestionnaire de paquets.  
avec par exemple pour debian:

    $ apt-get install phantomjs

=head1 DOCUMENTATION

Après installation, vous pouvez trouver la documentation avec la commande:

    $ perldoc Pstreamer::App

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

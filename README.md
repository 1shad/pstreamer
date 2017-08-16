## Pstreamer::App - Application de streaming vidéo

    Version 0.006

## DESCRIPTION

Pstreamer permet de visionner des films ou des series,  
en streaming, depuis un terminal, sur un système de type Unix.

Il se connecte à certains sites français. Permet de les parcourir  
via les liens disponibles ou par son menu, et permet de faire des recherches.  
Les vidéos sont lues depuis les hébergeurs avec mpv.

## UTILISATION

Pour lancer pstreamer, exécutez:

    $ pstreamer

## INTERFACES

Il y a deux interfaces disponibles: 'text' et 'ncurses'.  
L'interface text est utilisée par défault.

### TEXT

Le programme affiche les liens avec des numéros en début de ligne.  
Taper le numéro de la ligne puis entrée pour continuer ou alors  
écrire un texte pour lancer une recherche.

Les commandes du prompt disponibles sont:

    :p précédent
    :m afficher le menu du site
    :s afficher les sites
    :q quitter
    :h aide  

### NCURSES

Le programme affiche les liens disponible. Selectionner le lien  
en descandant ou en montant avec les flèches du clavier bas et haut,  
ou avec les touches 'k' et 'j', puis valider avec la touche entrer ou  
fleche droite ou 'l'.  
Revenir en arrière avec les touches flèche gauche ou 'h'.  

Voici la liste des racourcis:

    'j', 'bas'    : descendre dans la liste
    'k', 'haut'   : monter dans la liste
    'h', 'gauche' : precedant
    'l', 'droite' : suivant

    's' : menu selection d'un site
    'm' : menu du site (inactif si aucun site n'est selectionner)
    '>' : recherche

    Control-q : quitter

## OPTIONS

Les options de la ligne de commande sont prioritaires  
par rapport à celles du fichier de configuration.

### --version|-v

Affiche la version.

### --fullscreen|--fs

Lance mpv en plein écran. Désactivée par défault.

### --no-fullscreen

Désactive le plein écran, si l'option est activée dans  
le fichier de configuration.

### --ncurses

Active l'interface ncurses

### --no-ncurses

Désactive l'interface ncurses si l'option est activée  
dans le fichier de configuration.

### --go

Cette option n'est disponible que avec l'interface text,  
donc cette interface est automatiquement utilisé avec.

Elle permet d'automatiser les entrées.  
Le programme etant un 'bot', elle est utile pour réaliser des  
scripts ou des alias pour faire des bookmarks.  
Vous trouverez un exemple de script à la fin de cette section.

Les commandes utilisées sont celles de l'interface text, plus  
la commande 'print'.

Donc au lieu d'entrer dans le programme,  
puis taper 2,entrer,'ma serie',entrer,0,entrer

Vous pouvez ecrire: 

    $ pstreamer --go=2,'ma série',0

Si vous souhaitez juste afficher les résultats, pour vérifier  
qu'un épisode est disponible, il faut utiliser la commande 'print'.

exemple:

    $ pstreamer --go=2,'ma serie',2,1,print

le programme affiche les résultats puis quitte.  
Si vous utilisez la commande ':q', le programme  
n'affichera pas les résultats, donc il faut remplacer ':q'  
par 'print'.

Si il n'y a rien derrière print le programme quitte,  
sinon il continue avec ce qui suit.

Voici un petit script bash à lancer avec la crontab  
qui permet d'alerter l'utilisateur qu'un episode est  
disponible:

    #!/bin/bash
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

C'est bien sur completement inutile mais si besoin,  
a adapter selon votre recherche et votre installation.

## CONFIGURATION

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

Exemple d'un fichier INI:

    # config.ini
    user_agent = Mozilla/5.0 (X11; Linux) AppleWebKit/538.15...
    fullscreen = 1
    cookies = 1

Note pour les cookies:  
Pstreamer utilisera un fichier pour stocker les cookies si  
vous activer l'option.  
C'est utile pour cloudflare IMUA, mais pas encore optimisé.  
Donc l'option n'est pas disponible pour la ligne de commande.  

L'emplacement du fichier est pour l'instant:

    $HOME/.config/pstreamer/cookies/

## DEPENDENCES

### Modules perl requis:

- Moo
- utf8::all
- Mojolicious
- IO::Socket::SSL
- MooX::Singleton
- MooX::Options
- MooX::ConfigFromFile
- Class::Inspector
- Term::ReadLine::Gnu
- File::HomeDir
- Data::Record
- Regexp::Common
- Try::Tiny
- Curses::UI

### Modules perl recommandés:

- WWW::Mechanize::PhantomJS
- Config::Tiny

### Programme externe requis:

- mpv, [https://mpv.io/](https://mpv.io/)

### Programme externe recommandé:

- phantomjs, [http://phantomjs.org/](http://phantomjs.org/)

## INSTALLATION

Pour installer pstreamer, exécutez:

    $ git clone https://github.com/1shad/pstreamer.git
    $ cd pstreamer

Si vous avez une installation locale de perl.  
Vous pouvez installer depuis le répertoire en utilisant cpanm,  
qui installera les dépendances :

    $ cpanm .

Sinon, installez les dépendances, avec par exemple pour debian :

    $ apt-get install libmoo-perl libutf8-all-perl libmojolicious-perl \
    libio-socket-ssl-perl libmoox-singleton-perl libmoox-options-perl \
    libmoox-configfromfile-perl libclass-inspector-perl libfile-homedir-perl \
    libtry-tiny-perl libdata-record-perl libregexp-common-perl \
    libterm-readline-gnu-perl libconfig-tiny-perl libcurses-ui-perl

Et ensuite depuis le répertoire :

    $ perl Makefile.PL
    $ make
    $ make test
    $ sudo make install

NB:  
Veuillez installer la librairie libncursesw5-dev, si vous  
utilisez cpanm, avant d'installer le module Curses.  
Sinon l'utf-8 ne sera pas pris en compte.

## MISES A JOUR

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

## INSTALLATION DE WWW::Mechanize::PhantomJS

Phantomjs n'est utilisé que pour l'hebergeur openload.  
Comme il n'y a pas de paquet pour l'installer il faut le faire avec cpanm.

Si vous souhaitez l'installer, voilà la procédure :

Installez Object::Import :

    $ cpanm Object::Import

Ca échoue,  
Alors comme indiqué dans ce patch:  
[http://cpan.cpantesters.org/authors/id/S/SR/SREZIC/patches/Object-Import-1.004-RT106769.patch](http://cpan.cpantesters.org/authors/id/S/SR/SREZIC/patches/Object-Import-1.004-RT106769.patch)  
Il faut modifier un fichier: 

    $ cd ~/.cpanm/latest-build/Object-Import-1.004

Editez le fichier t/04\_handle.t avec par exemple:

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

## DOCUMENTATION

Après installation, vous pouvez trouver la documentation avec la commande:

    $ perldoc Pstreamer::App

## BUGS

Veuillez signaler tout bugs ou demandes de fonctionnalités via l'interface Web:  
[https://github.com/1shad/pstreamer/issues](https://github.com/1shad/pstreamer/issues).  
Je serai informé, et vous serez automatiquement informé de l'avancement.  

Please report any bugs or feature requests through the web interface at:  
[https://github.com/1shad/pstreamer/issues](https://github.com/1shad/pstreamer/issues).  
I will be notified, and then you'll automatically be notified of progress  
on your bugs as I make changes.

## LICENSE AND COPYRIGHT

Copyright 2017 1shad.

This program is free software; you can redistribute it and/or modify it  
under the terms of either: the GNU General Public License as published  
by the Free Software Foundation; or the Artistic License.  

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.  

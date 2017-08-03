## Pstreamer::App - Application de streaming vidéo

    Version 0.005

## DESCRIPTION

Pstreamer permet de visionner des films ou des series,  
en streaming, depuis un terminal. Il fonctionne sous GNU/Linux.

Il se connecte à certains sites français. Permet de les parcourir  
via les liens disponibles ou par son menu, et permet de faire des recherches.  
Les vidéos sont lues depuis les hébergeurs avec mpv.

## UTILISATION

Pour lancer pstreamer, exécutez:

    $ pstreamer

Le programme affiche les liens avec des numéros en début de ligne.  
Taper le numéro de la ligne puis entrée pour continuer ou alors  
écrire un texte pour lancer une recherche.

Les commandes du prompt disponibles sont:

    :p précédent
    :m afficher le menu du site
    :s afficher les sites
    :q quitter
    :h aide  

## OPTIONS

Les options de la ligne de commande sont prioritaires  
par rapport à celles du fichier de configuration.

### --version|-v

Affiche la version.

### --fullscreen|--fs

Lance mpv en plein écran. Désactivée par défault.

### --no-fullscreen

Désactive le plein écran, si l'option est activée dans  
fichier de configuration.

### --go

pstreamer est capable d'automatiser les entrées.

Avec cette option, vous pouvez aller directement à la page  
voulue, si vous connaissez d'avance les numéros et les textes  
que vous auriez écrit en lancant le programme.  

exemple 1: 

    $ pstreamer  --go=2,'ma série'

    permet de sélectionner le 3eme site, puis
    de faire une recherche avec le texte 'ma série'.
    pstreamer affiche les résultats, puis le prompt.

exemple 2:

    $ pstreamer --fs --go=2,'ma serie',2,1,0,0,:q

    pstreamer lance automatiquement l'épisode avec 
    mpv en plein ecran. Il quitte juste apres mpv.

exemple 3:

    $ pstreamer --go=2,'ma serie',2,2,0,0,:p,1,0,:q

    enchaine automatiquement les deux premiers épisodes
    de 'ma serie' puis quitte.

'print' permet d'afficher les résultats.

Si vous exécutez:

    $ pstreamer --go=2,'ma serie',:q

le programme quitte mais n'affiche rien.

Il faut alors entrer:

    $ pstreamer --go=2,'ma serie',print

pstreamer affiche les résultats puis quitte.

Si il n'y a rien derrière print le programme quitte,  
sinon il continue avec ce qui suit.

## CONFIGURATION

Vous pouvez utiliser un fichier de configuration, si vous  
le souhaitez, pour paramétrer quelques propriétés ou options.

Le format du fichier est libre, mais dépends d'un certain module.  
Installez un des modules de la liste pour utiliser le format voulue.

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
    libterm-readline-gnu-perl libconfig-tiny-perl

Et ensuite depuis le répertoire :

    $ perl Makefile.PL
    $ make
    $ make test
    $ sudo make install

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

Déja, phantomjs n'est utilisé que pour l'hebergeur openload.  
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

## NAME

Pstreamer::App - Streaming with perl 

## VERSION

Version 0.001

## DESCRIPTION

    Pstreamer permet de visionner des films ou des series,
    en streaming, depuis un terminal. Il fonctionne sous GNU/Linux.

    Il se connecte à certains sites français. Perrmet de parcourir le site
    via les liens disponibles ou par son menu, et permet de faire des recherches.
    Les vidéos sont lues depuis les hebergeurs avec mpv.

## UTILISATION

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

## OPTIONS

### --fullscreen|--fs

    Lance mpv en plein ecran.
    

### --go

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
        

## INSTALLATION

    Pour installer pstreamer, exécuter:
       
       git clone https://github.com/1shad/pstreamer.git
       cd pstreamer
       perl Makefile.PL
       make
       make install

## DOCUMENTATION

    Après installation, vous pouvez trouver la documentation avec la commande:
       perldoc Pstream::App

## DEPENDENCES

### Modules perl requis:

- Moo
- utf8::all
- Mojolicious
- WWW::Mechanize::PhantomJS
- MooX::Singleton
- MooX::Options
- Class::Inspector
- Term::ANSIColor
- Term::ReadLine::Gnu
- Scalar::Util
- File::Spec
- Try::Tiny

### Programmes externes requis:

- mpv, [https://mpv.io/](https://mpv.io/)
- phantomjs, [http://phantomjs.org/](http://phantomjs.org/)

    Pour phantomjs, il est recommandé de télécharger la version depuis le site
    plutôt que de l'installer avec votre gestionnaire de paquets. Et ensuite,
    faites en sorte que l'exécutable soit dans votre PATH.

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

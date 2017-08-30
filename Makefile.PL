use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    INSTALLMAN3DIR   => 'none',
    NO_PACKLIST      => 1,
    NO_PERLLOCAL     => 1,
    EXE_FILES        => [ 'bin/pstreamer' ],
    NAME             => 'Pstreamer::App',
    AUTHOR           => q{1shad},
    VERSION_FROM     => 'lib/Pstreamer/App.pm',
    ABSTRACT_FROM    => 'lib/Pstreamer/App.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'     => '0',
        'Test::Output'   => '0',
    },
    PREREQ_PM => {
        'Moo'                       => '0',
        'utf8::all'                 => '0',
        'Mojolicious'               => '0',
        'IO::Socket::SSL'           => '0',
        'MooX::Singleton'           => '0',
        'MooX::Options'             => '0',
        'MooX::ConfigFromFile'      => '0',
        'Class::Inspector'          => '0',
        'Term::ANSIColor'           => '0',
        'Term::ReadLine'            => '0',
        'Scalar::Util'              => '0',
        'File::Spec'                => '0',
        'File::HomeDir'             => '0',
        'File::Basename'            => '0',
        'Try::Tiny'                 => '0',
        'Data::Record'              => '0',
        'Regexp::Common'            => '0',
        'Term::ReadLine::Gnu'       => '0',
        'Curses'                    => '0',
        'Curses::UI'                => '0',
        'Gtk3'                      => '0',
        'Glib'                      => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'pstreamer-*' },
);

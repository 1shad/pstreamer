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
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
        'Moo'                       => '0',
        'utf8::all'                 => '0',
        'Mojolicious'               => '0',
        'WWW::Mechanize::PhantomJS' => '0',
        'MooX::Singleton'           => '0',
        'MooX::Options'             => '0',
        'Class::Inspector'          => '0',
        'Term::ANSIColor'           => '0',
        'Term::ReadLine::Gnu'       => '0',
        'Scalar::Util'              => '0',
        'File::Spec'                => '0',
        'Try::Tiny'                 => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'pstreamer-*' },
);

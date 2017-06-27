#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pstreamer::App' ) || print "Bail out!\n";
}

diag( "Testing Pstreamer::App $Pstreamer::App::VERSION, Perl $], $^X" );

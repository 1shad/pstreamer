#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 43;

BEGIN {
    use_ok( 'Pstreamer::App' ) || print "Bail out!\n";
    use_ok( 'Pstreamer::Config' );
    use_ok( 'Pstreamer::Host' );
    use_ok( 'Pstreamer::Site' );
    use_ok( 'Pstreamer::Viewer' );
    
    use_ok( 'Pstreamer::Role::UA' );
    use_ok( 'Pstreamer::Role::UI' );
    use_ok( 'Pstreamer::Role::Site' );
    
    use_ok( 'Pstreamer::Util::CloudFlare' );
    use_ok( 'Pstreamer::Util::CookieJarFile' );
    use_ok( 'Pstreamer::Util::Unpacker' );
    use_ok( 'Pstreamer::Util::Unwise' );

    use_ok( 'Pstreamer::Site::LibreStream' );
    use_ok( 'Pstreamer::Site::Radego' );
    use_ok( 'Pstreamer::Site::SokroStream' );
    use_ok( 'Pstreamer::Site::PapyStreaming' );
    use_ok( 'Pstreamer::Site::Skstream' );
    use_ok( 'Pstreamer::Site::StreamingSeriescx' );
    use_ok( 'Pstreamer::Site::Streamay' );
    use_ok( 'Pstreamer::Site::Sample' );
    
    use_ok( 'Pstreamer::Host::Cloudy' );
    use_ok( 'Pstreamer::Host::Mystream' );
    use_ok( 'Pstreamer::Host::Speedvid' );
    use_ok( 'Pstreamer::Host::Vidlox' );
    use_ok( 'Pstreamer::Host::Easyvid' );
    use_ok( 'Pstreamer::Host::Netu' );
    use_ok( 'Pstreamer::Host::Streamango' );
    use_ok( 'Pstreamer::Host::Vidoza' );
    use_ok( 'Pstreamer::Host::Estream' );
    use_ok( 'Pstreamer::Host::Nowvideo' );
    use_ok( 'Pstreamer::Host::Streamin' );
    use_ok( 'Pstreamer::Host::Vidto' );
    use_ok( 'Pstreamer::Host::GoogleDrive' );
    use_ok( 'Pstreamer::Host::Okru' );
    use_ok( 'Pstreamer::Host::Uptostream' );
    use_ok( 'Pstreamer::Host::Vidup' );
    use_ok( 'Pstreamer::Host::Itazar' );
    use_ok( 'Pstreamer::Host::Openload' );
    use_ok( 'Pstreamer::Host::Vidabc' );
    use_ok( 'Pstreamer::Host::Watchers' );
    
    use_ok( 'Pstreamer::UI::Text' );
    use_ok( 'Pstreamer::UI::Curses' );
    use_ok( 'Pstreamer::UI::Gtk' );
}

diag( "Testing Pstreamer::App $Pstreamer::App::VERSION, Perl $], $^X" );

use Test::More tests => 5;

BEGIN {
    use_ok( Pstreamer::Host ) || print "Bail out!\n";
}

ok ( my $host = Pstreamer::Host->new,
    'can Pstreamer::Host->new') || print "Bail out!\n";

subtest 'Pstreamer::Host can run functions' => sub {
    for( qw( _get_host get_filename) ) {
        can_ok( $host, $_ );
    }
};

subtest 'Pstreamer::Host->_get_host' => sub {
    ok( ! defined $host->_get_host,
        'call with no param should not succeed' );

    ok( !defined $host->_get_host('http://pstream.unknown.test/'),
        'call with an unknown string should not succeed');
    
    ok( my $h = $host->_get_host('http://sample.test/'),
        'call with a known string should succeed');

    isa_ok( $h, 'Pstreamer::Host::Sample',
        '... and returned object isa');
};

subtest 'Pstreamer::Host->get_filename' => sub {
    ok( ! defined $host->get_filename,
        'call with no param  should not succeed' );
    
    ok( ! defined $host->get_filename('http://pstream.unknown.test/'),
        'call with an unknown url should not succeed' );

    ok( my $res = $host->get_filename('http://pstream.sample.test/'),
        'call with a known url should succeed');

    is( $res, 'http://pstream.sample.test/video.mp4',
        '... and returned value should be correct' );
};

done_testing();

# to run test use:
# $ prove -lv t/03-host.t

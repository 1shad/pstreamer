use Test::More tests => 6;

BEGIN {
    use_ok ( Pstreamer::Viewer ) || print "Bail out!\n";
}

ok( my $viewer = Pstreamer::Viewer->new,
    'can Pstreamer::Viewer->new' ) || print "Bail out!\n";

subtest 'Pstreamer::Viewer can run functions' => sub {
    for( qw(ua can_run run stream _player _parse_url config) ) {
        can_ok( $viewer, $_ );
    }
};

subtest 'Pstreamer::Viewer->config' => sub {
    ok( defined $viewer->config,
        'should start defined' );
    isa_ok( $viewer->config, 'Pstreamer::Config',
        '... and isa should be ok' );
};

subtest 'Pstreamer::Viewer->stream' => sub {
    ok( ! defined $viewer->stream,
        'call with no param should not succeed' );
};

subtest 'Pstreamer::Viewer->_parse_url' => sub {
    ok( ! defined $viewer->_parse_url,
        'call with no param should not succeed');
    
    ok( my ( $file, $headers ) = $viewer->_parse_url('http://a/b.mp4'),
        'call with param and no headers should succeed' );
    is ( $file, 'http://a/b.mp4',
        '... and first returned value should be correct' );
    ok( defined $headers,
        '... and second returned value should be defined' );
    is( ref($headers), 'HASH',
        '... ... and it should be a HASH' );
    cmp_ok( keys %{$headers}, '==', 0,
        '... ... and it should be empty' );
    
    ok( ( $file, $headers ) = $viewer->_parse_url('abc.mp4|&name=value&other&'),
        'call with param and headers should succeed' );
    is ( $file, 'abc.mp4',
        '... and first returned value should be correct' );
    ok( defined $headers,
        '... and second returned value should be defined' );
    is( ref($headers), 'HASH',
        '... ... and it should be a HASH' );
    cmp_ok( keys %{$headers}, '==', 2,
        '... ... and number of keys should be correct' );
    is( $headers->{name}, 'value',
        '... ... and first pair (key, value) should be correct' );
    is( $headers->{other}, '1',
        '... ... and second pair (key, value) should be correct' );
};


done_testing();

# to run test use:
# prove -lv t/04-viewer.t

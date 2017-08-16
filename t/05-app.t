use Test::More tests => 8;

BEGIN {
    use_ok ( Pstreamer::App ) || print "Bail out!\n";
}

ok( my $app = Pstreamer::App->new,
    'can Pstreamer::Viewer->new' ) || print "Bail out!\n";

subtest 'Pstreamer::Viewer can run functions' => sub {
    for( qw(new_with_options) ) {
        can_ok( $app, $_ );
    }
    for( qw(config ua tx  viewer host site cf UI history) ) {
        can_ok( $app, $_ );
    }
    for (qw(proceed_search proceed_previous proceed run)) {
        can_ok( $app, $_);
    }
    for( qw(_init _proceed_line _proceed_host _is_internal _get) ) {
        can_ok( $app, $_ );
    }
};

subtest 'Pstreamer::App->_init' => sub {
    ok( $app->_init, 'call _init should suceed' );
    ok( $app->config, '.. and config should be defined' );
    isa_ok( $app->config, 'Pstreamer::Config', '... ... and isa' );
    ok( $app->viewer, '.. and viewer should be defined' );
    isa_ok( $app->viewer, 'Pstreamer::Viewer', '... ... and isa' );
    ok( $app->host, '.. and host should be defined' );
    isa_ok( $app->host, 'Pstreamer::Host', '... ... and isa' );
    ok( $app->site, '.. and site should be defined' );
    isa_ok( $app->site, 'Pstreamer::Site', '... ... and isa' );
    ok( $app->cf, '.. and cf should be defined' );
    isa_ok( $app->cf, 'Pstreamer::Util::CloudFlare', '... ... and isa' );
    ok( $app->ua, '.. and ua should be defined' );
    isa_ok( $app->ua, 'Mojo::UserAgent', '... ... and isa' );
    ok( $app->UI, '.. and UI should be defined' );
    isa_ok( $app->UI, 'Pstreamer::UI::Text', '... ... and isa' );
};

subtest 'Pstreamer::App->proceed_search' => sub {
    # no site active so should not succeed
    ok( ! $app->proceed_search('test'), 'call should not succeed')
};

subtest 'Pstreamer::App->_proceed_host' => sub {
    ok( ! $app->_proceed_host(), 
        'call with no param should not succeed')
};

subtest 'Pstreamer::App->_proceed_line' => sub {
    ok( ! $app->_proceed_line(undef),
        'call with an undefined param should not succeed');
    ok( ! $app->_proceed_line('test'),
        'call with a non hash param should not succeed');
    ok( ! $app->_proceed_line( {test => 'test'} ),
        'call with a hash param and no key url should not succeed');
    ok( ! $app->_proceed_line( {test => undef} ),
        'call with a hash param and undefined key url should not succeed');
};

subtest 'Pstreamer::App->history' => sub {
    is_deeply( $app->{history}, [], 'should start empty');
    ok ( $app->history == undef,
        '... and getting an element when it is empty should returns undef');
    ok( $app->history('a'), 'adding an element should succeed' );
    is_deeply( $app->{history},['a'],
        '... and the history array should be correct' );
    ok( $app->history('b','c'), 'adding several element should succeed' );
    is_deeply( $app->{history}, ['c','b','a'],
        '... and the history array should be correct' );
    is( $app->history, 'c', 'geting should return the first element' );
    is_deeply( $app->{history}, ['b','a'],
        '... and the history array should have lost the first element' );
};

done_testing();

# to run test use:
# prove -lv t/05-app.t

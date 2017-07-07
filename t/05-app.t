use Test::More tests => 11;
use Test::Output;
use Term::ANSIColor 'colored';

BEGIN {
    use_ok ( Pstreamer::App ) || print "Bail out!\n";
}

ok( my $app = Pstreamer::App->new,
    'can Pstreamer::Viewer->new' ) || print "Bail out!\n";

subtest 'Pstreamer::Viewer can run functions' => sub {
    for( qw(new_with_options) ) {
        can_ok( $app, $_ );
    }
    for( qw(config ua tx stash term viewer host site cf command history) ) {
        can_ok( $app, $_ );
    }
    for( qw(_init run _proceed_command _proceed_line _proceed_search _get ) ) {
        can_ok( $app, $_ );
    }
    for( qw(_print_choices _is_command _is_internal) ) { 
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
    ok( $app->term, '.. and term should be defined' );
    isa_ok( $app->term, 'Term::ReadLine', '... ... and isa' );
};

subtest 'Pstreamer::App->_proceed_command' => sub {
    ok( $app->_proceed_command(':s'), 'call with :s should succeed' );
    ok( ! $app->_proceed_command(':m'), 'call with :m should not succeed' );
    ok( ! $app->_proceed_command(':p'), 'call with :p should not succeed' );
};

subtest 'Pstreamer::App->_proceed_search' => sub {
    ok( ! $app->_proceed_search('test'), 'call should not succeed')
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

subtest 'Pstreamer::App->_print_choices' => sub {
    stdout_is( sub { $app->_print_choices( ({ name=>'test' }) ) },
        ' '.colored(0, 'bold').": test\n",
        'output should be correct with valid params' );
    stdout_is( sub { $app->_print_choices() },
        '',
        'output should be correct with no params' );
    stdout_is( sub { $app->_print_choices( ( 
            { name => 'test' },
            { name => undef },
            { name => '' },
            { abcd => 'abcd' },
            [ 'name', 'abcd' ],
            undef,
            'name',
        ))},
        ' '.colored(0, 'bold').": test\n",
        'output should be correct with unvalid params' );
};

subtest 'Pstreamer::App->_is_command' => sub {
    ok( ! $app->_is_command(), 'call with no param should not succeed' );
    ok( ! $app->_is_command(':q:s'),
        'call with an unvalid param should not succeed' );
    ok( $app->_is_command('  :q abcd '),
        'call with a valid param should succeed');
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

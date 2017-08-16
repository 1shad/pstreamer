use Test::More;
use File::Basename;

plan tests => 12; 

use_ok( Pstreamer::Config );

ok( my $config = Pstreamer::Config->instance,
    'get an instance should be ok' );

subtest 'Pstreamer::Config->ua' => sub {
    ok( defined $config->ua, 'should be defined' );
    isa_ok( $config->ua, 'Mojo::UserAgent',
        '... and isa should be ok' );
};

subtest 'Pstreamer::Config->ui' => sub {
    ok( defined $config->ui, 'should be defined' );
    isa_ok( $config->ui, 'Pstreamer::UI::Text',
        '... and isa should be ok' );
};

subtest 'Pstreamer::Config->user_agent' => sub {
    ok( defined $config->user_agent, 'should be defined' );
    is( $config->user_agent, 
        'Mozilla/5.0 (X11; Linux i686; rv:45.0) Gecko/20100101 Firefox/45.0',
        '... and its value should be correct'
    );
};

subtest 'Pstreamer::Config->header_accept' => sub {
    ok( defined $config->header_accept, 'should be defined' );
    is( $config->header_accept,
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'and its value should be correct'
    );
};

subtest 'Pstreamer::Config->cookies_file' => sub {
    ok( defined $config->cookies_file, 'should be defined' );
    is( basename($config->cookies_file), 'cookies.txt', 
        '... and its basename value should be correct' );
};

subtest 'Pstreamer::Config->config_file' => sub {
    ok( defined $config->config_file, 'should be defined' );
    is( basename($config->config_file), 'config.ini',
        '... and its basename value should be correct' );
};

subtest 'Pstreamer::Config->config_prefix' => sub {
    ok( defined $config->config_prefix, 'should be defined' );
    is( $config->config_prefix, 'config',
        '... and its value should be correct' );
};

subtest 'Pstreamer::Config->config_identifier' => sub {
    ok( defined $config->config_identifier, 'should be defined' );
};

subtest 'Pstreamer::Config->cookies' => sub {
    ok( ! defined $config->cookies, "should start undefined" );
};

subtest 'Pstreamer::Config->fullscreen' => sub {
    ok( ! defined $config->fullscreen, "should start undefined" );
};

done_testing();

# to run test use:
# $ prove -lv t/01-config.t

package My::REQ;
sub new { shift };
sub url { '/' };
sub dom { 1 };

package My::TX;
sub new { shift }
sub req { My::REQ->new };
sub res { My::REQ->new };

package Main;
use Test::More tests => 8 ;
use Mojo::URL;

BEGIN {
    use_ok( Pstreamer::Site ) || print "Bail out!\n";
}

my $msg = '^^ -- can not continue further';

ok ( my $site = Pstreamer::Site->new,
    'can Pstreamer::Site->new' ) || print "Bail out!\n";

subtest 'Pstreamer::Site can run functions' => sub {
    for( qw(current get_sites url menu search get_results params) ) {
        can_ok( $site, $_ );
    }
};

subtest "Pstreamer::Site->current" => sub {
    ok( ! defined $site->current, 'should start undefined' );
    
    ok( ! $site->current('unknown'),
        '... and setting its value with an unknown string should not succeed');
    
    ok( $site->current('sample'),
        '... and setting its value with a known string should succeed' )
        ||BAIL_OUT( $msg );
    
    isa_ok( $site->current, 'Pstreamer::Site::Sample',
        '... and isa should be ok' );
};

subtest "Pstreamer::Site->url" => sub {
    isa_ok( $site->url, 'Mojo::URL', 'default isa should be ok' );
    
    ok( ! $site->url(undef),
        '... and settings its value with undef should not succeed' );
    
    ok( $site->url('test'),
        '... and settings its value with a string should succeed' );
    is( $site->url, 'test',
        '... and getting its value should be correct' );
    isa_ok( $site->url, 'Mojo::URL', '... and its isa should be ok' );

    ok( $site->url('http://one.test.fr/a/b/c'),
        '... and settings its value with an absolute url should succeed' );
    is( $site->url, 'http://one.test.fr/a/b/c',
        '... and getting its value should be correct' );
    isa_ok( $site->url, 'Mojo::URL', '... and its isa should be ok' );
    
    ok( $site->url('/one.test.fr/a/b/c'),
        '... and settings its value with non absolute url should succeed' );
    is( $site->url, '/one.test.fr/a/b/c',
        '... and getting its value should be correct' );
    isa_ok( $site->url, 'Mojo::URL', '... and its isa should be ok' );
};

subtest 'Pstreamer::Site->menu' => sub {
    $site->current('sample'); # refresh
    ok( my $element = shift @{$site->menu}, 
        'default menu should have one element');
    is( ref($element), 'HASH', '... and it is an HASH' );
    isa_ok( $element->{url}, 'Mojo::URL',
        '... and its key {url} isa should be ok');
    is( $element->{url}, '/',
        '... and its key {url} value should be correct' );
    is( $element->{name}, 'Home',
        '... and its key {name} value should be correct' ); 
};

subtest 'Pstreamer::Site->_trigger_url' => sub {
    $site->current('sample'); # refresh
    ok ( ! $site->_trigger_url( undef ), 
        'call with an undefined value should not succeed' );
    
    ok ( ! $site->_trigger_url( Mojo::URL->new('/test/') ),
        'call with a non abs url should not succeed');
    ok( my $element = $site->menu->[0], 
        '... and default menu should still have an element');
    is( $element->{url}, '/',
        '... and its url should not have been changed');

    $site->current('sample'); # refresh
    ok ( $site->_trigger_url( Mojo::URL->new('http://test.pl') ),
        'call with abs url should succeed');
    ok( $element = $site->menu->[0], 
        '... and default menu should still have an element');
    is( $element->{url}, 'http://test.pl/',
        '... and its url should have been changed');

    $site->current('sample'); # refresh
    ok ( $site->_trigger_url( Mojo::URL->new('https://test2.pl/a/b/c') ),
        'call with abs url, url parts and no trailing slash should succeed');
    ok( $element = $site->menu->[0], 
        '... and default menu should still have an element');
    is( $element->{url}, 'https://test2.pl/a/b/c',
        '... and its url should have been changed');

    $site->current('sample'); # refresh
    ok ( $site->_trigger_url( Mojo::URL->new('https://test3.pl/a/b/c/') ),
        'call with abs url, url parts and a trailing slash should succeed');
    ok( $element = $site->menu->[0], 
        '... and default menu should still have an element');
    is( $element->{url}, 'https://test3.pl/a/b/c/',
        '... and its url should have been changed');

    # no refresh now, test the menu as it is
    ok ( $site->_trigger_url( Mojo::URL->new('http://test4.pl/') ),
        'call with abs, changing host, scheme and no parts should succeed');
    ok( $element = $site->menu->[0], 
        '... and default menu should still have an element');
    is( $element->{url}, 'http://test4.pl/a/b/c/',
        '... and its url should have been changed and saved the parts');
    
    ok ( $site->_trigger_url( Mojo::URL->new('https://test5.pl/i/j/k') ),
        'call with abs, changing host, scheme and parts should succeed');
    ok( $element = $site->menu->[0], 
        '... and default menu should still have an element');
    is( $element->{url}, 'https://test5.pl/a/b/c/',
        '... and its url should have been changed but not the parts');
};

subtest 'Pstreamer::Site->get_results' => sub {
    my $tx = My::TX->new; # mock
    ok( my @res = $site->get_results( $tx ),
        'call should succeed and returns an array');
    
    cmp_ok ( @res, '==', 2, '... and there should be two elements' );
    
    my $e1 = shift @res;
    my $e2 = shift @res;

    is( ref($e1), 'HASH', '... and first element is an hash' );
    is( $e1->{name}, 'default',
        "... ... and its element 'name' should be correct" );
    is( $e1->{url}, '/sample.test/page',
        "... ... and its element 'url' should be correct" );
    
    is( ref($e2), 'HASH', '... and second element is an hash' );
    is( $e2->{name}, 'next',
        "... ... and its element 'name' should be correct" );
    is( $e2->{url}, '/sample.test/next',
        "... ... and its element 'url' should be correct" );
};

done_testing();

# to run test use:
# $ prove -lv t/02-site.t

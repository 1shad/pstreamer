package My::REQ;
sub new { shift };
sub url { '/' };
sub dom { 1 };

package My::TX;
sub new { shift }
sub req { My::REQ->new };
sub res { My::REQ->new };

package Main;
use Test::More tests => 7 ;

BEGIN {
    use_ok( Pstreamer::Site ) || print "Bail out!\n";
}

ok ( my $site = Pstreamer::Site->new,
    'can Pstreamer::Site->new' ) || print "Bail out!\n";

subtest 'Pstreamer::Site can run functions' => sub {
    for( qw(current get_sites url menu search get_results params) ) {
        can_ok( $site, $_ );
    }
};

subtest "Pstreamer::Site->current" => sub {
    ok( ! defined $site->current, 'should start undefined' );
    
    $site->current('unknow');
    ok( ! defined $site->current,
        '... and setting its value with an unknown string should not succeed');
    
    $site->current('sample');
    ok( defined $site->current,
        '... and setting its value with a known string should succeed' );
    
    isa_ok( $site->current, 'Pstreamer::Site::Sample',
        '... and isa should be ok' );
};

subtest "Pstreamer::Site->url" => sub {
    isa_ok( $site->url, 'Mojo::URL', 'isa should be ok' );
    is( $site->url, '/sample.test', '... and its value should be correct' );
};

subtest 'Pstreamer::Site->menu' => sub {
    isa_ok( $site->menu->[0]->{url}, 'Mojo::URL', 'isa should be ok');
    my $element = shift @{$site->menu};
    is( ref($element), 'HASH', '... element is an HASH' );
    is( $element->{name}, 'Home',
        '... and name value should be correct' );
    is( $element->{url}, '/',
        '... and url value should be correct' );
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

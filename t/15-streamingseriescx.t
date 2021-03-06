use Test::More;
use Test::Mojo;

unless ( $ENV{PSTREAMER_TESTING} ) {
    plan( skip_all => "URL tests not required for installation" );
}

use_ok( Pstreamer::Site::StreamingSeriescx );
use_ok( Pstreamer::Util::CloudFlare );

my $t    = Test::Mojo->new;
my $site = Pstreamer::Site::StreamingSeriescx->new;
my $cf   = Pstreamer::Util::CloudFlare->new;

$site->_init;
# use the app ua
$t = $t->ua( $site->ua );
$t->ua->max_redirects(5);

# test menu links and results
foreach my $e ( @{$site->menu} ) {
    $t->get_ok( $e->{url} );
    $t->tx( $cf->bypass(0) ) if $cf->is_active( $t->tx );
    $t->status_is(200);
    cmp_ok( $site->get_results( $t->tx ), '>', 0, 'there are results' );
}

done_testing();

# to run test use:
# $ prove -lv t/15-streamingseriescx.t

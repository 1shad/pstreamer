use Test::More;
use Test::Mojo;
use Pstreamer::Site::SokroStream;
use Pstreamer::Util::CloudFlare;

unless ( $ENV{PSTREAMER_TESTING} ) {
    plan( skip_all => "URL tests not required for installation" );
}

my $t    = Test::Mojo->new;
my $site = Pstreamer::Site::SokroStream->new;
my $cf   = Pstreamer::Util::CloudFlare->new;

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
# $ prove -lv t/12-sokrostream.t

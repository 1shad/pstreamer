use Test::More tests => 6;

BEGIN {
    use_ok( Pstreamer::UI::Text ) || print "Bail out!\n";
}

ok ( my $ui = Pstreamer::UI::Text->new,
    'can Pstreamer::UI::Text->new') || print "Bail out!\n";

subtest 'Pstreamer::UI::Text can run functions' => sub {
    for( qw(init run _do_go _dispatch _proceed_command) ) {
        can_ok( $ui, $_ );
    }
    for( qw(status error wait_for) ) {
        can_ok( $ui, $_ );
    }
    for( qw(_print_list _is_command _help _build_term) ) {
        can_ok( $ui, $_ );
    }
};

subtest 'Pstreamer::UI::Text->term' => sub {
    ok( defined $ui->term , 'should be defined' );
    isa_ok( $ui->term, 'Term::ReadLine',
        '... and isa should be correct' );
};

subtest 'Pstreamer::UI::Text->init' => sub {
    ok( $ui->init, 'call should succeed' );
};

subtest 'Pstreamer::UI::Text->_is_command' => sub {
    ok( ! $ui->_is_command(),
        'call with no param should not succeed' );
    ok( ! $ui->_is_command(':q:s'),
        'call with unvalid param should not succeed' );
    ok( ! $ui->_is_command(' aaaa :q'),
        'call with unvalid param should not succeed' );
    ok( $ui->_is_command('  :q aaaa'),
        'call with valid param should succeed');
};

done_testing();

# run test with:
# $ prove -lv t/06-ui-text.t

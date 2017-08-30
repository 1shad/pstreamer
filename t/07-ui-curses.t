use Test::More tests => 4;

BEGIN {
    use_ok( Pstreamer::UI::Curses ) || print "Bail out!\n";
}

ok( my $ui = Pstreamer::UI::Curses->new,
    'can Pstreamer::UI::Curses->new') || print "Bail out!\n";

subtest 'Pstreamer::UI::Curses can run functions' => sub {
    for (qw(init run controller list site_list menu_list site_name)) {
        can_ok( $ui, $_);
    }
    for (qw(status error wait_for nostatus)) {
        can_ok( $ui, $_);
    }

};

subtest 'Pstreamer::UI::Curses->init' => sub {
    ok( $ui->init, 'call should succeed');
    $ui->cui->leave_curses;
    isa_ok( $ui->cui, 'Curses::UI',
        '... and cui isa should be correct' );
    isa_ok( $ui->win, 'Curses::UI::Window',
        '... and win isa should be correct' );
    isa_ok( $ui->listbox, 'Curses::UI::Listbox',
        '... and listbox isa should be correct' );
    isa_ok( $ui->footer, 'Curses::UI::Label',
        '... and footer isa should be correct' );
};

done_testing();

# run test with:
# $ prove -lv t/07-ui-curses.t


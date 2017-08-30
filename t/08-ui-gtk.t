use Test::More tests => 4;

BEGIN {
    use_ok( Pstreamer::UI::Gtk ) || print "Bail out!\n";
}

ok( my $ui = Pstreamer::UI::Gtk->new,
    'can Pstreamer::UI::Gtk->new') || print "Bail out!\n";

subtest 'Pstreamer::UI::Gtk can run functions' => sub {
    for (qw(init run controller list site_list menu_list site_name)) {
        can_ok( $ui, $_);
    }
    for (qw(status error wait_for nostatus)) {
        can_ok( $ui, $_);
    }
};

subtest 'Pstreamer::UI::Gtk->init' => sub {
    ok( $ui->init, 'call should succeed');
    isa_ok( $ui->window, 'Gtk3::Window',
        '... and window isa should be correct' );
    isa_ok( $ui->header_bar, 'Gtk3::HeaderBar',
        '... and header_bar isa should be correct' );
    isa_ok( $ui->listbox, 'Gtk3::ListBox',
        '... and listbox isa should be correct' );
    isa_ok( $ui->status_text, 'Gtk3::Label',
        '... and status_text isa should be correct' );
};

done_testing();

# run test with:
# $ prove -lv t/08-ui-gtk.t


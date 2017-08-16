package Pstreamer::UI::Curses;

=head1 NAME

 Pstreamer::UI::Curses

=cut

#
# needs libncursesw5 for utf-8 support
# needs libncursesw5-dev to compile Curses module
# 

use utf8;
use Curses;
use Curses::UI;
use Curses::UI::Common;
use Moo;

has [qw(cui win listbox footer status_win)] => ( is => 'rw' );

has controller => (
    is => 'rw',
    handles => [qw(proceed proceed_search proceed_previous)],
);

has [qw(data_list site_list menu_list)] => ( is => 'rw' );

sub init {
    my $self = shift;

    $self->cui( Curses::UI->new(
        -color_support => 1,
        -mouse_support => 0,
        -language => 'fr',
        -debug => 0,
        -clear_on_exit => 1,
    ));
            
    $self->win( $self->cui->add(
        'win', 'Window',
    ));

    $self->listbox( $self->win->add(
        'mylistbox', 'Listbox',
        -border => 1,
        -title => "Selectionner un site",
        -titlereverse => 0,
        -bfg => 'blue',
        -padbottom => 1,
        -y => 0,
    ));

    $self->footer( $self->win->add(
        'myfooter', 'Label',
        -text => "Pstreamer",
        -width => -1,
        -textalignment => 'middle',
        -y => - 1,
    ));
    
    # callbacks
    $self->listbox->onChange( sub{
        my $l = shift;
        $self->status('Chargement');
        $self->proceed( $self->data_list->[$l->get] );
    });

    $self->listbox->set_routine('loose-focus', sub {
        $self->status('Chargement');
        $self->proceed_previous;
    });
    
    # Bindings
    $self->cui->set_binding( sub{ exit 0; }, "\cQ" );
    
    $self->cui->set_binding( sub{
        $self->about_dialog();
    }, "\cA" );

    $self->listbox->set_binding( sub{}, KEY_BTAB(), CUI_TAB() );
    
    $self->listbox->set_binding( sub{
        $self->search_entry();
    }, ">" );

    $self->listbox->set_binding( sub{
        $self->popup_menu('menu');
    }, "m" );
    
    $self->listbox->set_binding( sub{
        $self->popup_menu('site');
    }, "s" );
 
}

sub run {
    my $self = shift;

    # catch term resize
    $SIG{WINCH} = sub {
        $self->cui->leave_curses;
        $self->cui->reset_curses;
        $self->status_win->draw if $self->status_win;
    };

    # focus listbox
    $self->listbox->focus;
    # mainloop
    $self->cui->mainloop;
}


sub about_dialog {
    my $self = shift;
    $self->cui->dialog(
        -title    => "About",
        -message  => "Programme: Pstreamer \n"
            ."\n"
            ."Regarder des vidéos en streaming avec mpv\n"
            ."\n"
            ."2017"
    );
}

sub list {
    my ( $self, $arr ) = @_;
    my @array = map { $_->{name} } @{$arr};
    
    my $values = [ 0 .. $#array ];
    my $c = 0;
    my %labels;
    
    foreach my $e ( @array ) {
        $labels{$c++} = $e;
    }

    $self->listbox->values( $values );
    $self->listbox->labels( \%labels );
    $self->data_list( $arr );
    $self->nostatus;
}

sub popup_menu {
    my ( $self, $type ) = @_;
    my $list;

    return unless $type;
    
    $list = $type eq 'menu' ? $self->menu_list : $self->site_list;
    return unless $list;

    $self->win->delete('popup');
    
    my @array = map{ $_->{name} } @{ $list };

    my $values = [ 0 .. $#array ];
    my $c = 0;
    my %labels;
    
    foreach my $e ( @array ) {
        $labels{$c++} = $e;
    }

    my $menu = $self->win->add(
        'popup', 'Popupmenu',
        -values  => $values,
        -labels => \%labels,
        -x => 1,
    );
    
    $menu->set_binding( sub{
        shift->loose_focus;
        $self->win->delete('popup');
        $self->listbox->focus;
    }, CUI_ESCAPE, "h", KEY_LEFT(), KEY_DOWN(), KEY_UP() );

    $menu->set_routine('loose-focus', sub {
        my $menu = shift;
        $menu->loose_focus;
        $self->win->delete('popup');
        $self->listbox->focus;
    });
    
    $menu->onChange( sub {
        my $m = shift;
        $self->status('Patience');
        $self->proceed( $list->[$m->get] );
        $m->run_event('loose-focus');
        $self->listbox->focus;
    });
    
    $menu->focus;
    $menu->open_popup;
}

sub search_entry {
    my $self = shift;
    
    $self->cui->delete('searchwin');
    my $w = $self->cui->add(
        'searchwin', 'Window',
        -y => -1,
        -height => 1,
    );
    my $l = $w->add('l', 'Label', -text => '>> ');
    my $t = $w->add('e', 'TextEntry', -x => 3 );
    
    $t->set_binding( sub{
        $self->cui->delete('searchwin');
        $self->listbox->focus;
    }, CUI_ESCAPE );
    
    $t->set_routine('loose-focus', sub {
        my $entry = shift;
        $self->status('Chargement');
        $self->proceed_search( $entry->get );
        $entry->loose_focus;
        $self->cui->delete('searchwin');
        $self->listbox->focus;
    });

    $t->focus;
}

sub status {
    my ( $self, $message ) = @_;
    
    $self->nostatus;
    my $status = $self->win->add(
        'mystatus', 'Dialog::Status',
        -message => $message,
    );
    $status->draw;
    $self->status_win( $status );
}

sub error {
    my ( $self, $message ) = @_;
    
    $self->nostatus;
    my $status = $self->win->add(
        'mystatus', 'Dialog::Status',
        -fg => 'red',
        -message => $message,
    );
    $status->draw;

    sleep(1);
    $self->nostatus;
}

sub nostatus{
    my $self = shift;
    $self->win->delete('mystatus');
    $self->status_win( undef );
    $self->listbox->focus;
}

sub wait_for {
    my ( $self, $seconds, $message ) = @_;
    return unless $seconds and $message;

    while ( $seconds > 0 ) {
        $self->status( $message." ".$seconds."s" );
        sleep(1);
        $seconds--;
    }
}

sub site_name {
    my ( $self, $name ) = @_;
    $name //= 'Selectionner un site';

    $self->listbox->title( $name );
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

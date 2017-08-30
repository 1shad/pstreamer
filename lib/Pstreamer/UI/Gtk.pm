package Pstreamer::UI::Gtk;

=head1 NAME

 Pstreamer::UI::Gtk

=cut

use strict;
use warnings;
use feature 'say';
use Gtk3 -init;
use Glib 'TRUE','FALSE';
use Moo;

has controller => (
    is => 'rw',
    handles => [qw(proceed proceed_search proceed_previous )],
);

has [qw(window header_bar listbox status_text site_menu)] => ( is => 'rw' );
has [qw(site_btn menu_btn data_list)] => ( is => 'rw' );

sub init {
    my $self = shift;
    
    #_____/ Window \___________________________________________________________
    $self->window( Gtk3::Window->new( 'toplevel' ) );
    $self->window->set_default_size( 400, 300 );
    $self->window->signal_connect( destroy => sub { Gtk3->main_quit; } );
    
    #_____/ Boxes \____________________________________________________________
    my $vertical_box = Gtk3::Box->new( 'vertical', 0);
    my $head_box     = Gtk3::Box->new( 'vertical', 0);
    my $box_left     = Gtk3::Box->new( 'horizontal', 0);
    my $box_right    = Gtk3::Box->new( 'horizontal', 0);

    #_____/ Icons \____________________________________________________________
    my $previous_icon = Gtk3::Image->new_from_icon_name(
        'go-previous-symbolic',
        'menu'
    );

    my $search_icon = Gtk3::Image->new_from_icon_name(
        'edit-find-symbolic',
        'menu'
    );
    
    #_____/ Search Bar \_______________________________________________________
    my $search_bar = Gtk3::SearchBar->new;
    
    #_____/ Search Entry \_____________________________________________________
    my $entry = Gtk3::SearchEntry->new;
    #$entry->set_width_chars( 75 );

    #_____/ Header Bar \_______________________________________________________
    $self->header_bar( Gtk3::HeaderBar->new );
    $self->header_bar->set_show_close_button( TRUE );
    $self->header_bar->set_has_subtitle( FALSE );
    $self->header_bar->set_property( spacing =>  0 );
    $self->header_bar->set_decoration_layout("menu:close");

    #_____/ Scrolled Window \__________________________________________________
    my $scrolls = Gtk3::ScrolledWindow->new;

    #_____/ Status text \______________________________________________________
    $self->status_text( Gtk3::Label->new("") );
    $self->status_text->set_use_markup( TRUE );
    $self->status_text->set_property( 'margin', 5 );

    #_____/ Status Bar \_______________________________________________________
    
    #_____/ Listbox \__________________________________________________________
    $self->listbox( Gtk3::ListBox->new );
    $self->listbox->set_selection_mode( 'browse' );
    $self->listbox->set_property('expand', TRUE );

    #_____/ Buttons \__________________________________________________________
    my $previous_btn  = Gtk3::Button->new;
    my $search_btn    = Gtk3::ToggleButton->new;
    my $site_btn      = Gtk3::MenuButton->new;
    my $menu_btn      = Gtk3::MenuButton->new;

    #_____/ Site Menu \________________________________________________________
    $self->site_btn( $site_btn );
    $self->menu_btn( $menu_btn );
    
    #_____/ Icons to Buttons \_________________________________________________
    $previous_btn->add( $previous_icon );
    $search_btn->add( $search_icon );
    
    #_____/ Buttons reflief \__________________________________________________
    $previous_btn->set_relief('none');
    $search_btn->set_relief('none');
    $site_btn->set_relief('none');
    $menu_btn->set_relief('none');

    #_____/ Placement \________________________________________________________
    $box_left->add( $previous_btn );
    $box_left->add( $site_btn );
    $box_right->add( $menu_btn );
    $box_right->add( $search_btn );

    $self->header_bar->pack_start( $box_left );
    $self->header_bar->pack_end( $box_right );

    $search_bar->add( $entry );
    $search_bar->connect_entry( $entry );
    
    $head_box->add( $self->header_bar );
    $head_box->add( $search_bar );
    
    # set window titlebar with head box
    $self->window->set_titlebar( $head_box );

    $scrolls->add( $self->listbox );
    $vertical_box->add( $scrolls );
    $vertical_box->add( Gtk3::Separator->new( 'horizontal' ) );
    $vertical_box->add( $self->status_text );
    $self->window->add( $vertical_box );

    #_____/ Signals \__________________________________________________________
    # toggle Button search
    $search_btn->signal_connect('toggled' => sub {
        my $toggle = shift;
        $search_bar->set_search_mode( $toggle->get_active );
    });
    
    # Search entry
    $entry->signal_connect( 'activate' => sub {
        my $e = shift;
        $self->status('Chargement');
        $self->proceed_search( $e->get_text() );
        $self->nostatus;
        $search_btn->set_active(FALSE);
    });
    
    # Previous button
    $previous_btn->signal_connect( 'clicked' => sub {
        $self->status('Chargement');
        $self->proceed_previous;
    });
    
    # Listbox row activated
    $self->listbox->signal_connect( 'row-activated', sub {
        my ( $listbox, $row ) = @_;
        $self->status('Chargement');
        $self->proceed( $self->data_list->[$row->get_index()] );
    });
    
    # Listbox key press
    $self->listbox->signal_connect( 'key-press-event', sub {
        my ( $listbox, $event ) = @_;
        $self->_listbox_key_events( $event );
        return FALSE;
    });

    # Window keypress ( exit with Ctrl-q )
    $self->window->signal_connect( 'key-press-event' => sub {
        my ( $window, $event ) = @_;
        
        if ( $event->keyval == Gtk3::Gdk::KEY_q ) {
            if( $event->state & 'control-mask' ) {
                Gtk3->main_quit();
            }
        }

       return FALSE;
    });

}

sub run {
    my $self = shift;
    
    $self->site_name( 'Pstreamer');
    $self->window->show_all;
    Gtk3->main;
}

# Listbox key events
sub _listbox_key_events {
    my ( $self, $event ) = @_;
    
    if ( $event->keyval == Gtk3::Gdk::KEY_Left ) {
        $self->status('Chargement');
        $self->proceed_previous;
    }
    elsif ( $event->keyval == Gtk3::Gdk::KEY_Right ) {
        my $row = $self->listbox->get_selected_rows;
        $row->[0]->activate if ( @$row > 0 );
    }
    
}

# Clear listbox content
sub clear_list {
    my $self = shift;
    return unless $self->listbox;
    $self->listbox->foreach( sub{
        $self->listbox->remove( shift ) 
    });
}

# Populate listbox
sub list {
    my ( $self, $arr ) = @_;
    
    $self->clear_list();
    foreach ( @$arr ) {
        my $l = Gtk3::Label->new( $_->{name} );
        $l->set_xalign(0);
        $self->listbox->insert( $l, -1 );
    }
    $self->data_list( $arr );
    $self->nostatus;
    $self->listbox->show_all;
}

# Site choices popup menu
sub site_list {
    my ( $self, $array ) = @_;
    $self->_create_menu( $self->site_btn, $array );
}

# Site internal links popup menu 
sub menu_list {
    my ( $self, $array ) = @_;
    $self->_create_menu( $self->menu_btn, $array );
}

# Create, populate and create callbacks for a menu, given an array
sub _create_menu {
    my ( $self, $button, $array ) = @_;
    
    unless( $array ) {
        $button->set_popup( undef );
        return;
    }

    my $menu = Gtk3::Menu->new();
    $button->set_popup( $menu );

    foreach my $item ( @$array ) {
        my $menu_item = Gtk3::MenuItem->new( $item->{name} );
        $menu_item->signal_connect('activate', sub {
            $self->status('Chargement');
            $self->proceed( $item );
        });
        $menu->append( $menu_item );
    }

    $menu->show_all;
}

# Display a status message
sub status {
    my ( $self, $message ) = @_;
    $self->listbox->set_sensitive( FALSE );
    $self->status_text->set_markup( "<span><b>".$message."</b></span>");
    Gtk3::main_iteration while ( Gtk3::events_pending );
}

# Display an error message
sub error {
    my ( $self, $message ) = @_;

    $self->listbox->set_sensitive( FALSE );
    $self->status_text->set_markup(
        "<span foreground='red'><b>"
        .$message
        ."</b></span>"
    );
    Gtk3::main_iteration while ( Gtk3::events_pending );
    sleep(1);
}

# Clear a status or an error message
sub nostatus {
    my $self = shift;
    $self->listbox->set_sensitive( TRUE );
    $self->status_text->set_markup( "" );
    Gtk3::main_iteration while ( Gtk3::events_pending );
}

# Display a status message with a timer
sub wait_for {
    my ( $self, $seconds, $message ) = @_;
    return unless $seconds and $message;

    while ( $seconds > 0 ) {
        $self->status( $message." ".$seconds."s" );
        sleep(1);
        $seconds--;
        #Gtk3::main_iteration while ( Gtk3::events_pending );
    }
}

# Change the title bar text
sub site_name {
    my ( $self, $name ) = @_;
    $name //= 'Pstreamer';

    $self->header_bar->set_title( $name );

}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


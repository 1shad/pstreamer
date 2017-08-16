package Pstreamer::UI::Text;

=head1 NAME

 Pstreamer::UI::Text;

=cut

use utf8;
use feature 'say';
use Scalar::Util qw(looks_like_number refaddr reftype);
use Term::ANSIColor 'colored';
use Term::ReadLine;
use Moo;

has term => ( is => 'ro', builder => 1 );

has controller => (
    is => 'rw',
    handles => [qw(proceed proceed_search proceed_previous go)],
);

has [qw(list site_list menu_list site_name command)] => ( is => 'rw' );

# init
sub init {
    my $self = shift;

    $self->command( [qw(:quit :h :s :p :m)] );
    $self->term->addhistory( $_ ) for @{$self->command};
    push @{$self->command}, qw(:q q :exit);
}

# main loop
sub run {
    my $self = shift;
    my ( $line, $text );
    
    $self->_do_go if @{$self->go};

    while( 1 ) {
        $self->_print_list( @{$self->list} );
        $text = $self->site_name ? "( ".$self->site_name." )" : "";
        $line = $self->term->readline(colored( $text.">>> ", 'bold'));
        $self->_dispatch( $line );
    }
}

sub _do_go {
    my ( $self ) = @_;
    my $line;

    while ( @{$self->go} ) {
        my $line = shift @{$self->go};
        if ( $line eq 'print' ) {
            $self->_print_list( @{$self->list} );
            $line = shift @{$self->go} // ':q';
        }
        $self->_dispatch( $line );
    }
}

# dispatcher
sub _dispatch {
    my ( $self, $line ) = @_;
    
    return unless defined $line and $line ne "";

    if ( $self->_is_command( $line ) ) {
        $self->_proceed_command( $line );
    }
    elsif ( looks_like_number($line) && $line < @{$self->list} ) {
        $self->proceed( $self->list->[$line] );
    }
    else {
        $self->proceed_search( $line );
    }
}

# processes the choosen command by the user
sub _proceed_command {
    my ( $self, $line ) = @_;
    
    $line =~ s/\s*([^\s]*)\s*.*/$1/;
    exit if $line =~ /^(:q|q|:quit|:exit)$/;

    if ( $line eq ":s" ) {
        return undef unless $self->site_list;
        $self->list( $self->site_list );
    }
    elsif ( $line eq ":m" ) {
        return undef unless $self->menu_list;
        $self->list( $self->menu_list );
    }
    elsif ( $line eq ":p"){
        $self->proceed_previous;
    } else {
        $self->_help;
    }
}

# prints a status message
sub status {
    my ( $self, $message ) = @_;
    say colored( $message, 'bold' );
}

# prints an error message
sub error {
    my ( $self, $message ) = @_;
    say colored( $message, 'red' );
}

# waits for seconds and prints formated message
sub wait_for {
    my ( $self, $seconds, $message ) = @_;
    return unless $seconds and $message;

    $|++;
    while ( $seconds > 0 ) {
        print $message." ".$seconds."s\r";
        sleep(1);
        $seconds--;
    }
    print ' 'x(length($message)+10) ."\r";
    $|--;
}

# formats and prints the array of choices
sub _print_list {
    my ( $self, @choices ) = @_;
    my $count = 0;
    
    @choices = grep {
        defined
        and refaddr($_)
        and reftype($_) eq reftype {}
        and $_->{name}
    } @choices;

    @choices = map {
        join '', ($count>9?"":" ",colored($count++ ,'bold'),": ",$_->{name});
    } @choices;

    say join "\n", @choices if @choices;
}

# returns true or false if the param is a command or not
sub _is_command {
    my ( $self, $line ) = @_;
    return undef unless $line;
    
    $line =~ s/\s*([^\s]*)\s*.*/$1/;
    
    my $commands = join '|', @{$self->command};
    return  $line =~ /^($commands)$/;
}

# prints help
sub _help {
    my $self = shift;
    my @text;

    push @text, "[Recherche]";
    push @text, "taper un texte puis Entrée";
    push @text, "\n[Commandes]";
    push @text, ":s\t: Afficher les sites";
    push @text, ":m\t: Afficher le menu du site";
    push @text, ":p\t: Précedent";
    push @text, ":q\t: Quitter le programme. alias: q, :quit, :exit\n";
    say  join "\n", @text;
    $self->term->readline('Appuyer sur Entrée pour continuer');
}

# term builder
sub _build_term {
    my $self = shift;

    my $term = Term::ReadLine->new("term.readline", \*STDIN, \*STDOUT);
    $term->Attribs->ornaments(0);

    return $term;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

package Pstreamer::Util::CloudFlare;

=head1 NAME

 Pstreamer::Util::CloudFlare

=head1 SYPNOSIS

    ...
    my $ua = Mojo::UserAgent->new;
    my $cf = CloudFlare->new;
    my $tx = $ua->get('http://.....');
    $tx = $cf->bypass if $cf->is_active($tx);
    ...

=cut

use utf8;
use feature 'say';
use Mojo::URL;
use Moo;

my $DEBUG = 0;

has tx => ( is => 'rw'); #Mojo::Transaction::HTTP

with 'Pstreamer::Role::UA', 'Pstreamer::Role::UI';

sub is_active {
    my ( $self, $tx ) = @_;
    $self->{tx} = $tx;
    return $self->tx->result->dom
        =~ /Checking your browser before accessing/ ;
}

sub _parse {
    my ( $self, $text ) = @_;
    $text =~ s/!!\[\]/1/g;
    $text =~ s/!\+\[\]/1/g;
    $text =~ s/(\([^()]+)\+\[\]\)/$1)*10/g;
    $text =~ s/\(\+\[\]\)/0/g;
    return $text;
}

sub _get_challenge {
    my $self = shift;

    my @tab = $self->tx->result->dom
        =~ /var s,t,o,p,b,r,e,a,k,i,n,g,f, (.+?)=\{"(.+?)":\+*(.+?)\};/;
    my $var = $tab[0].'.'.$tab[1];
    my $res = $self->_parse( $tab[2] );
    
    $res = eval($res);
    return undef unless defined $res;
    say '$res='.$res if $DEBUG;

    @tab = $self->tx->result->dom =~ /;$var([*\-+])=([^;]+)/g;
    return undef unless @tab % 2 == 0;
    
    while ( my @t = splice(@tab, 0, 2) ){
        say '$res'.$t[0]."=".$self->_parse($t[1]) if $DEBUG;
        eval '$res'.$t[0]."=".$self->_parse($t[1]);
    }
    
    $res += length $self->tx->req->url->host;
    say $res if $DEBUG;

    return $res;
}

sub _get_results {
    my $self = shift;
    
    my $mojo_uri = Mojo::URL->new( $self->tx->req->url );
    my $dom = $self->tx->result->dom;
    
    my $uri_abs = $dom->at('#challenge-form')->attr('action');
    my %params = $dom->find('#challenge-form input')
        ->map( sub { $_->attr('name') => $_->attr('value') } )
        ->each;
    
    $params{jschl_answer} = $self->_get_challenge;
    $uri_abs = Mojo::URL->new($uri_abs)->to_abs($mojo_uri);

    return ( $uri_abs->to_string , \%params );
}

sub bypass {
    my ( $self, $verbose ) = @_;
    my $url = $self->tx->req->url;
    my @results = $self->_get_results;
    my $t = 4;
    
    # verbose by default
    # use ->bypass(0) for non verbose.
    $verbose //= 1;
    
    if( $verbose ) {
        $self->wait_for( $t, "Débloquage cloudflare:");
    } else {
        sleep( $t );
    }
    
    my $headers = { 'Referer' => $url->to_string };
    
    $self->ua->max_redirects( 2 );
    my $res = $self->ua->get( $results[0] => $headers => form => $results[1] );
    $self->ua->max_redirects( 0 );
    
    return $res

}
1;

=head1 DESCRIPTION

 Bypass cloudflare IMUA

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

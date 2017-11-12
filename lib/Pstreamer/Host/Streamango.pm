package Pstreamer::Host::Streamango;

=head1 NAME

 Pstreamer::Host::Streamango

=cut

use Moo;

with 'Pstreamer::Role::UA';

sub get_filename {
    my ( $self, $url ) = @_;
    my ( $tx, $dom, $file, $e, $c );

    $tx = $self->ua->get( $url );
    return 0 unless $tx->success;
    $dom = $tx->res->dom;

    ($e, $c) = $dom =~ /srces\.push\(\{type:\"video\/mp4\",src:\w+\('([^']+)',(\d+)/;
    $file = $self->decode( $e, $c );
    return 0 unless $file;

    return $file = [{
            url => 'http:'.$file,
            stream => 1,
        }];
}

sub decode {
    my( $self, $encoded, $code ) = @_;
    my( @juice, %index, $t );
    my ( $n, $r, $i, $s, $o, $u, $a ) = (0)x7;

    $t = "";

    # set up the array
    @juice = ( 'A'..'Z', 'a'..'z', 0..9,'+','/','=' );
    @juice = reverse( @juice );

    # Create an index
    @index{@juice} = (0..$#juice);

    # check
    return 0 unless ( (length($encoded) % 4) == 0 );
    # Decode
    foreach my $word ( $encoded =~ /(....)/g ) {
        ( $s, $o, $u, $a ) = map { $index{ $_ } } split //, $word;
        
        $n = $s << 2 | $o >> 4;
        $r = ( 15 & $o ) << 4 | $u >> 2;
        $i = ( 3 & $u ) << 6 | $a;
        $n = $n ^ $code;

        $t .= chr($n);
        $t .= chr($r) if 64 != $u;
        $t .= chr($i) if 64 != $a;
    }

    return $t;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


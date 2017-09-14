package Pstreamer::Util::Unjuice;

=head1 NAME

 Pstreamer::Util::Unjuice

=cut

use strict;
use warnings;
use Pstreamer::Util::Unpacker 'jsunpack';
use Exporter 'import';

our @EXPORT_OK = qw(&unjuice);

my @juice = ( 'A'..'Z', 'a'..'z', 0..9,'+','/','=' );

sub unjuice {
    my $e = shift;
    my %index;
    my $t = "";
    my ( $n, $r, $i, $s, $o, $u, $a, $f ) = (0)x8;

    return 0 unless $e;
    return 0 unless _is_valid( $e );

    # Create an index
    @index{@juice} = (0..$#juice);

    # Extraction and format
    ($e) = $e =~ /JuicyCodes.Run\(([^\)]+)/i;
    $e =~ s/"\s*\+\s*"//g;
    $e =~ s/[^A-Za-z0-9\+\/=]//g;

    # Check
    return 0 unless ( (length($e) % 4) == 0 );
    
    # Decode
    foreach my $word ( $e =~ /(....)/g ) {
        ( $s, $o, $u, $a ) = map { $index{ $_ } } split //, $word;

        $n = $s << 2 | $o >> 4;
        $r = ( 15 & $o ) << 4 | $u >> 2;
        $i = ( 3 & $u ) << 6 | $a;

        $t .= chr($n);
        $t .= chr($r) if 64 != $u;
        $t .= chr($i) if 64 != $a
    }

    $t = jsunpack( \$t ) if $t;
    
    return $t;
}

sub _is_valid {
    my $e = shift;

    return $e =~ /JuicyCodes.Run\(/i;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


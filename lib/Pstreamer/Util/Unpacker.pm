package Pstreamer::Util::Unpacker;

use strict;
use warnings;
use Exporter 'import';

=head1 NAME

Pstreamer::Util::Unpacker - JavaScript unpacker for Dean Edward's p.a.c.k.e.r

=cut

our @EXPORT_OK = qw(&jsunpack);

use constant BASE62 => join '', 0..9, 'a'..'z', 'A'..'Z';
use constant BASE95 => join '', map(chr, 32 .. 126);

my %DICT = ( 62 => BASE62, 95 => BASE95 );

my $reg1 = qr/\Qeval(function(p,a,c,k,e,\E[r|d]?.*split\('\|'\)/;
my $reg2 = qr/}\('(.*)', *([\d|\W]+), *(\d+), *'(.*?)'\.split\('\|'\)/;

sub jsunpack {
    my ( $packed ) = @_;
    my ( $payload, $radix, $count, $keywords, $dict );
    my ( $counter, $selector ) = (0, 62) ;

    return 0 unless _is_valid( $packed );

    ($payload, $radix, $count, $keywords ) = $$packed =~ $reg2; 

    $keywords = [ split /\|/, $keywords ];
    $radix = 62 if ( $radix =~ /\[\]/); # JavaScript::Packer 
    $selector = 95  if $radix > 62;
    $dict = { map { ( $_ => $counter++) } split(//, $DICT{$selector}) };
    
    $payload =~ s/\\n/\n/g; # for '//' js comments
    $payload =~ s/(\b\w+\b)/_decode($1, $radix, $keywords, $dict )/ge;
    $payload =~ s/\\//g;

    return $payload;
}

sub _decode{
    my ( $word, $radix, $keywords, $dict ) = @_;
    my ( $result, $digit ) = (0, 0);
    
    if( 2 <= $radix && $radix <= 10 ){
        $result = $keywords->[$dict->{$word}];
        return $result eq "" ? $word : $result;
    }

    for my $char ( split( //, reverse $word) ) {
        my $value = $dict->{$char};
        $result += $value * ( int($radix) ** $digit++ );
    }
    
    return $word unless defined $keywords->[$result];
    return $keywords->[$result] eq "" ? $word
                : $keywords->[$result];
}

sub _is_valid {
    my $packed = shift;
    
    if ( $$packed !~ /\Qeval(function(p,a,c,k,e,\E[r|d]?.*split\('\|'\)/ ) {
        return 0;
    }
    
    # four args needed by the unpacker    
    my ($p,$a,$c,$k) 
        = $$packed =~ /}\('(.*)', *([\d|\W]+), *(\d+), *'(.*?)'\.split\('\|'\)/;
    return 0 if !($p && $a && $c && $k);
    
    # numbers of words should be equal 
    #$k = split /\|/, $k;
    
    #>> test remove because i believe some packer doesn't set it correctly
    #>> or i didn't understood ...
    
    #warn "Numbers of words should be equal" if $k != $c;
    #return 0 if $k != $c;
    
    return 1;
}

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

package Pstreamer::Util::Unwise;

=head1 NAME

 Pstreamer::Util::Unwise

=head1 SYPNOSIS

 use Pstreamer::Util::Unwise 'unwise';
 ...
 my $html = ...;
 $html = unwise( $html );
 ...

=cut

use utf8;
use Carp 'croak';
use Exporter 'import';

our @EXPORT_OK = qw(&unwise);


my $reg1 = 
qr/(;?eval\s*\(\s*function\s*\(\s*w\s*,\s*i\s*,\s*s\s*,\s*e\s*\).+?[\"\']\s*\)\s*\)(?:\s*;)?)/;

my $reg2 =
qr/\}\s*\(\s*[\"\'](\w*)[\"\']\s*,\s*[\"\'](\w*)[\"\']\s*,\s*[\"\'](\w*)[\"\']\s*,\s*[\"\'](\w*)[\"\']/;


sub unwise {
    my $js = shift;
    
    while ( my ($a) = $js =~ $reg1 ) {
        
        my @wise = $a =~ $reg2;
        #last if ( @wise == 0 );
        last unless @wise;

        if( $a !~ /while/ ){
            $js =~ s/\Q$a/_unwise2($wise[0])/e;
        } else {
            $js =~ s/\Q$a/_unwise1($a,@wise)/e;
        }
    }

    return $js;
}

sub _unwise1{
    my ( $js, @wise ) = @_;
    
    my $counter = 0;
    my @wisestr = ("", "", "", "" );
    my @wiseint = (0,0,0,0);
    my ($b) = $js =~/while(.+?)var\s*\w+\s*=\s*\w+\.join\(\s*["']["']\s*\)/;
    my @tmp = $b =~ /if\s*\(\s*\w*\s*<\s*(\d+)\)\s*\w+\.push/g;

    for (@tmp){
        $wisestr[$counter] = $wise[$counter] ;
        $wiseint[$counter++] = int($_);
    }

    return _process_unwise1(
        [split('', $wisestr[0])],
        [split('', $wisestr[1])],
        [split('', $wisestr[2])],
        [split('', $wisestr[3])],
        $wiseint[0],
        $wiseint[1],
        $wiseint[2],
        $wiseint[3],
    );
}

sub _unwise2{
    my @str = split '', shift;
    my @res;

    while ( my @t = splice(@str, 0, 2) ) {
        push @res, chr( _decode_base36( join '', @t ) );
    }

    return join '', @res;
}

sub _process_unwise1{
    my ($w, $i, $s, $e, $wi, $ii, $si, $ei ) = @_;
    my ($v1, $v2, $v3, $v4) = (0,0,0,0);
    my ($str1, $str2) = ([],[]);
    my @result;

    while (1) {
        if ( @{$w} > 0 ) {
            if ( $v1 < $wi ) {
                push @{$str2}, $w->[$v1];
            }
            elsif ( $v1 < @{$w} ) {
                push @{$str1}, $w->[$v1];
            }
            $v1++;
        }

        if ( @{$i} > 0 ) {
            if ( $v2 < $ii ) {
                push @{$str2}, $i->[$v2];
            }
            elsif ( $v2 < @{$i} ) {
                push @{$str1}, $i->[$v2];
            }
            $v2++;
        }

        if ( @{$s} > 0 ) {
            if ( $v3 < $si ) {
                push @{$str2}, $s->[$v3];
            }
            elsif ( $v3 < @{$s} ){
                push @{$str1}, $s->[$v3];
            }
            $v3++;
        }
        
        if ( @{$e} > 0 ) {
            if ( $v4 < $ei ) {
                push @{$str2}, $e->[$v4];
            }
            elsif ( $v4 < @{$s} ){
                push @{$str1}, $e->[$v4];
            }
            $v4++;
        }
        
        last if ( @{$w} + @{$i} + @{$s} + @{$e} == @{$str1} + @{$str2} );
    }
    
    $v1 = 0;
    while ( my @t = splice( @{$str1}, 0, 2 ) ) {
        my $flag = ord( $$str2[$v1] ) % 2 ? 1 : -1 ;
        push @result, chr( _decode_base36( join '', @t ) - $flag);
        $v1 = 0 if ++$v1 >= @{$str2};
    }

    return join '', @result;
}

#
# From Math::Base36
# use of bigint remove as 'ZZ' = 1295 is the max int used
# so it's much faster
#
sub _decode_base36 {
    my $base36 = uc( shift );
    croak "Invalid base36 number ($base36)" if $base36 =~ m{[^0-9A-Z]};

    my ( $result, $digit ) = ( 0, 0 );
    for my $char ( split( //, reverse $base36 ) ) {
        my $value = $char =~ m{\d} ? $char : ord( $char ) - 55;
        #$result += $value * Math::BigInt->new( 36 )->bpow( $digit++ );
        $result += $value * ( 36 ** $digit++ );
    }

    return $result;
}

1;

=head1 DESCRIPTION

 Decode javascript type eval(function(w,i,s,e){...
 It exports the function 'unwise', that will replace all occurences
 of encrypted javascript with the decoded content.

=head1 SEE ALSO

 L<Pstreamer::App>

=cut

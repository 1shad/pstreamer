package Pstreamer::Util::Unpacker;

=head1 NAME

JavaScript::Unpacker - JavaScript unpacker for Dean Edward's p.a.c.k.e.r

=head1 VERSION

Version 0.30

=cut

our $VERSION = '0.30';

use feature 'say';
use Math::BigInt;
use Moo;

use constant BASE62 => join '', 0..9, 'a'..'z', 'A'..'Z';
use constant BASE95 => join '', map(chr, 32 .. 126);

my %DICT = ( 62 => BASE62, 95 => BASE95 );

has payload   => (is => 'ro', lazy => 1, init_arg => undef);
has radix     => (is => 'ro', lazy => 1, init_arg => undef);
has count     => (is => 'ro', lazy => 1, init_arg => undef);
has keywords  => (is => 'ro', lazy => 1, init_arg => undef);
has dict      => (is => 'ro', lazy => 1, init_arg => undef);

has packed => (
    is=>'rw',
    trigger => 1,
    isa => sub {
        die "packed is not valid !" if !is_valid($_[0]);
    }
);

sub _trigger_packed{
    my ($self, $packed) = @_;
    my ($counter, $selector) = (0, 62) ;

    ($self->{payload}, $self->{radix}, $self->{count}, $self->{keywords} )
        = $$packed =~ /}\('(.*)', *([\d|\W]+), *(\d+), *'(.*?)'\.split\('\|'\)/;

    $self->{keywords} = [ split /\|/, $self->{keywords} ];
    $self->{radix} = 62 if ( $self->{radix} =~ /\[\]/); 
    $selector = 95  if $self->{radix} > 62;
    %{$self->{dict}} = map { ( $_ => $counter++) } split(//, $DICT{$selector});
}

sub unpack{
    my $self = shift;
    my $result = $self->{payload};
    
    $result =~ s/\\n/\n/g; # for '//' js comments
    $result =~ s/(\b\w+\b)/$self->_decode($1)/ge;
    $result =~ s/\\//g;
    return $result;
}

sub _decode{
    my ($self, $word) = @_;
    my ( $result, $digit) = (0, 0);
    
    if( 2 <= $self->{radix} && $self->{radix} <= 10 ){
        $result = $self->{keywords}->[$self->{dict}->{$word}];
        return $result eq "" ? $word : $result;
    }
    
    for my $char ( split( //, reverse $word) ) {
        my $value = $self->{dict}->{$char};
        $result += $value 
            * Math::BigInt->new( int($self->{radix}) )->bpow( $digit++ );
    }
    return $word unless defined $self->{keywords}->[$result];
    return $self->{keywords}->[$result] eq "" ? $word
                : $self->{keywords}->[$result];
}

# Class function
sub is_valid {
    my $packed = shift;
    
    if ( $$packed !~ /\Qeval(function(p,a,c,k,e,\E[r|d]?.*split\('\|'\)/ ) {
        return 0;
    }
    
    # four args needed by the unpacker    
    my ($p,$a,$c,$k) 
        = $$packed =~ /}\('(.*)', *([\d|\W]+), *(\d+), *'(.*?)'\.split\('\|'\)/;
    return 0 if !($p && $a && $c && $k);
    
    # numbers of words should be equal 
    $k = split /\|/, $k;
    #return 0 if $k != $c;
    warn "Numbers of words not equal" if $k != $c;
    
    return 1;
}



=head1 SYNOPSIS


This module unpacks javascript packed via Dean Edward's tools.
L<http://dean.edwards.name/packer/>

Inspired by: 

=over

=item 

L<https://github.com/beautify-web/js-beautify/blob/master/python/jsbeautifier/unpackers/packer.py>

=item 

Math::Base36 L<http://search.cpan.org/perldoc?Math::Base36>

=back

Code snipet:

    use JavaScript::Unpacker;

    my $pack = "eval(function(p,a,c,k,e,r)....";

    my $unpacker = JavaScript::Unpacker->new( packed => \$pack );

    print $unpacker->unpack ."\n";
    
=cut


=head1 SUBROUTINES/METHODS

=head2 $unpacker->new()
    
=head2 $unpacker->new( packed => \$js )
    
    Creates and loads the packed javascript assigned by reference.
    It dies if the entry is not valid.
    
=head2 $unpacker->packed( \$js )

    Loads it by reference.
    Dies if not valid.
    
=head2 $unpacker->unpack()
    
    Returns a string, the unpacked javascript.

=head2 $unpacker->payload()
    
    Returns a string, ie the symbol tab.

=head2 $unpacker->radix()
    
    Returns the radix.

=head2 $unpacker->count()
    
    Returns the number of words.
    
=head2 $unpacker->keywords()
    
    Returns an array reference. Keywords extract by the encoder

=head2 $unpacker->dict()
    
    Returns a hash reference. The dictionnary used by JavaScript::Unpacker.
    
=head2 JavaScript::Unpacker::is_valid( \$js )
    
    Check the validity of a packed javascript.
    Returns a boolean.

=head1 AUTHOR

 shad

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 BUGS

Please report any bugs or feature requests through the web interface at


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JavaScript::Unpacker


=head1 LICENSE AND COPYRIGHT

Copyright 2017 shad.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of JavaScript::Unpacker

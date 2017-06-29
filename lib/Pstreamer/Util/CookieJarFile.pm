package Pstreamer::Util::CookieJarFile;

=head1 NAME

 Pstreamer::Util::CookieJarFile

=head1 SYPNOSIS

 ...
 my $ua = Mojo::UserAgent->new;
 my $cj = Pstreamer::Util::CookieJarFile->new( cookie_file => 'filename' );
 $ua = $ua->cookie_jar( $cj );
 ...

=cut

use Mojo::UserAgent::CookieJar -base;

our $VERSION = 0.01;

use Mojo::Cookie::Response;
use Mojo::Util qw( decode encode );
use Mojo::File;
use Scalar::Util 'blessed';
use Carp 'croak';

has 'cookie_file';

sub new {
    my ( $proto, %param ) = @_;
    my $self = shift->SUPER::new( %param );
    croak 'cookie_file must be specified' unless defined $self->{cookie_file};
    $self->_load_cookies;
    return $self;
}

sub _load_cookies {
    my $self = shift;
    return unless -r $self->cookie_file;
    my $path = Mojo::File->new( $self->cookie_file );
    my $content = decode 'UTF-8', $path->slurp;
    defined( $_ = $self->_parse_cookie($_)) and $self->SUPER::add($_) 
        for $content =~ /^.*$/mg;    
}

sub _format_cookie {
    my ( $self, $cookie ) = @_;
    return undef unless blessed $cookie;
    my $origin = $cookie->origin // $cookie->domain or return "\n";
    
    return sprintf "%s\t%s\t%s\t%s\t%u\t%s\t%s\n",
        $cookie->httponly ? '#HttpOnly_'.$origin: $origin,
        $cookie->{all_machines} // ($origin =~ /^\./) ? 'TRUE' : 'FALSE',
        $cookie->path // '/',
        $cookie->secure ? 'TRUE' : 'FALSE',
        $cookie->expires // 0,
        $cookie->name,
        $cookie->value;
}

#
# Returns a Mojo::Cookie::Response object 
# or returns undef if the cookie has expired
#
sub _parse_cookie {
    my ( $self, $text ) = @_;
    $text //= '';
    return undef unless length $text
        and ( $text !~ /^#/ or $text =~ /^#HttpOnly_/ ) ;
    
    my $httponly = 0;
    my ($origin, $all, $path, $secure, $expires, $name, $value) =
    $text =~ /^(\S+)\s+([A-Z]+)\s+(\S+)\s+([A-Z]+)\s+(\d+)\s+(\S+)\s+(.*)/;
    croak "Unrecognised cookie line:\n($text)" unless $name;

    return undef if $expires < time;
    
    $httponly = 1 if ( $origin =~ s/#HttpOnly_// );

    # little hack for cloudflare IMUA ...
    # needs investigations
    if ( $name =~ /cf_clearance/ ) {
        return undef if $expires < time + 3600;
    }

    return Mojo::Cookie::Response->new(
        domain => ($origin //= '') =~ s/^\.//r,
        origin => $origin,
        all_machines => $all eq 'TRUE',
        path => $path,
        secure => $secure eq 'TRUE',
        expires => $expires,
        name => $name,
        value => $value,
        httponly => $httponly,
    );
}

sub _save_cookies {
    my ( $self ) = @_;
    return unless $self->cookie_file;
    my $content = "# Cookies saved by CookieJarFile\n#\n";
    my $path = Mojo::File->new($self->cookie_file);
    $content .= $self->_format_cookie($_) for @{$self->all};
    # create the path if it doesn't exists
    $path->dirname->make_path;
    $path->spurt( encode ('UTF_8', $content ) );
}

# redefine collect
# call parent collect
# save cookie file only if there are cookies in tx
sub collect {
    my ( $self, $tx ) = @_;
    $self->SUPER::collect( $tx );
    $self->_save_cookies if @{$tx->res->cookies};
}

1;

=head1 DESCRIPTION

 This file extends Mojo::UserAgent::CookieJar.
 It uses transparently a file to load and store cookies between sessions.

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


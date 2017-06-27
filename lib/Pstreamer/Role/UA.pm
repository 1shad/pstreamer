package Pstreamer::Role::UA;

=head1 NAME

 Pstreamer::Role::UA

=cut

use Pstreamer::Config;
use Moo::Role;

has ua => ( 
    is => 'ro',
    default => sub { Pstreamer::Config->instance->ua; },
);

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


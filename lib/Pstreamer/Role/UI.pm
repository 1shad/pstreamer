package Pstreamer::Role::UI;

=head1 NAME

 Pstreamer::Role::UI

=cut

use Pstreamer::Config;
use Moo::Role;

has ui => ( 
    is => 'ro',
    default => sub { Pstreamer::Config->instance->ui; },
    handles => [qw(status error wait_for)],
);

1;

=head1 SEE ALSO

 L<Pstreamer::App>

=cut


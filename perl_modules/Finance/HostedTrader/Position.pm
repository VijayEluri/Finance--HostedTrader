package Finance::HostedTrader::Position;
=head1 NAME

    Finance::HostedTrader::Position - Trade object

=head1 SYNOPSIS

    use Finance::HostedTrader::Position;
    my $obj = Finance::HostedTrader::Position->new(
                );

=head1 DESCRIPTION


=head2 METHODS

=over 12

=cut

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

=item C<symbol>


=cut
has symbol => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=item C<trades>


=cut
has trades => (
    is     => 'ro',
    isa    => 'ArrayRef[Finance::HostedTrader::Trade]',
    builder => '_empty_list',
    required=>0,
);

=item C<profit>


=cut
sub profit {
    my ($self) = @_;

}

=item C<addTrade>


=cut
sub addTrade {
    my ($self, $trade) = @_;

    push @{$self->trades}, $trade;
}

=item C<close>


=cut
sub close {
    my ($self, $closeDate, $closePrice) = @_;

    my $size = 0;

    foreach my $trade (@{ $self->trades }) {
        $trade->close();
    }

    return $size;
}

=item C<size>


=cut
sub size {
    my ($self) = @_;

    my $size = 0;

    foreach my $trade (@{ $self->trades }) {
        if ($trade->direction eq 'long') {
            $size += $trade->size();
        } else {
            $size -= $trade->size();
        }
    }

    return abs($size);
}


sub _empty_list {
    return [];
}

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Trade>

=cut

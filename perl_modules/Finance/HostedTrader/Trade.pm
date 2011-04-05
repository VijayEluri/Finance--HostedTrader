package Finance::HostedTrader::Trade;
=head1 NAME

    Finance::HostedTrader::Config::Trade - Trade object

=head1 SYNOPSIS

    use Finance::HostedTrader::Trade;
    my $obj = Finance::HostedTrader::Trade->new(
                );

=head1 DESCRIPTION


=head2 METHODS

=over 12

=cut

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;


subtype 'positiveNum'
    => as 'Num'
    => where { $_ > 0 }
    => message { "The number provided ($_) must be positive" };

subtype 'positiveInt'
    => as 'Int'
    => where { $_ > 0 }
    => message { "The number provided ($_) must be a positive integer" };


=item C<id>


=cut
has id => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=item C<symbol>


=cut
has symbol => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=item C<direction>

long or short

=cut
enum 'tradeDirection' => qw(long short);
enum 'tradeStatus' => qw(open closed);
has direction => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);


=item C<openDate>


=cut
has openDate => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);


=item C<openPrice>


=cut
has openPrice => (
    is     => 'ro',
    isa    => 'positiveNum',
    required=>1,
);

=item C<size>


=cut
has size => (
    is     => 'ro',
    isa    => 'positiveInt',
    required=>1,
);


=item C<closeDate>


=cut
has closeDate => (
    is     => 'ro',
    isa    => 'Str',
    required=>0,
);

=item C<closePrice>


=cut
has closePrice => (
    is     => 'ro',
    isa    => 'Num',
    required=>0,
);

=item C<pl>


=cut
has pl => (
    is     => 'ro',
    isa    => 'Num',
    required=>0,
);

=item C<profit>


=cut
sub profit {
    my ($self) = @_;

    return undef if (!defined($self->closePrice));
    return sprintf("%.4f", $self->closePrice - $self->openPrice) if ($self->direction eq 'long');
    return sprintf("%.4f", $self->openPrice - $self->closePrice) if ($self->direction eq 'short');
    die('WTF');
}

=item C<status>


=cut
sub status {
    my ($self) = @_;

    return 'open' if (!defined($self->closePrice));
    return 'closed';
}

=item C<close>


=cut
sub close {
    my ($self, $closeDate, $closePrice) = @_;

    die('trade already closed') if ($self->status eq 'closed');
    $self->{closeDate} = $closeDate;
    $self->{closePrice} = $closePrice;
}

=item C<stopLoss>

=cut
sub exitValue {
    my ($self, $system);

    return $system->getExitValue($self->symbol, $self->direction);
}

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut

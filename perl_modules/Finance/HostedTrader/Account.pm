package Finance::HostedTrader::Account;
=head1 NAME

    Finance::HostedTrader::Account - Trade object

=head1 SYNOPSIS

    use Finance::HostedTrader::Account;
    my $obj = Finance::HostedTrader::Account->new(
                );

=head1 DESCRIPTION


=head2 METHODS

=over 12

=cut

use strict;
use warnings;
use Moose;
use Finance::HostedTrader::Position;
use Finance::HostedTrader::Trade;


use YAML::Syck;
use Data::Dumper;

YAML::Syck->VERSION( '0.70' );







##Specific to the simulator account
use Storable;
=item C<simulatedTime>


=cut
has simulatedTime => (
    is     => 'rw',
    isa    => 'Str',
    required=>0,
    'default' => '9999-12-31 23:59:59'
);

=item C<expressionParser>


=cut
has expressionParser => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::ExpressionParser',
    required=>1,
);


##These should exist everywhere, regardless of broker
=item C<username>


=cut
has username => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=item C<password>


=cut
has password => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=item C<positions>


=cut
has positions => (
    is     => 'ro',
    isa    => 'HashRef[Finance::HostedTrader::Position]',
    builder => '_empty_hash',
    required=>0,
);


=item C<getBalance>


=cut
sub getBalance {
    my ($self) = @_;

    return 15000;
}

=item C<getPosition>


=cut
sub getPosition {
    my ($self, $symbol) = @_;

    my $tradesFile = '/home/fxhistor/.wine/drive_c/trades.yml';
    $self->loadPositionsFromYML($tradesFile);

    return $self->_getPosition($symbol);
}

sub _writeTempFile {
    my ($prefix, $content) = @_;
    use File::Temp qw/ tempfile /;
    my ($fh, $filename) = tempfile($prefix.'.XXXXX', DIR => '/home/fxhistor/.wine/drive_c/orders');

    print $fh $content;
    close($fh);
    print STDERR $filename;
}

sub marketOrder {
    my ($self, $symbol, $direction, $maxLossCurrency, $stopLossValue) = @_;

    _writeTempFile 'open', "$symbol $direction $maxLossCurrency $stopLossValue";
}

sub closeTrades {
    my ($self, $symbol) = @_;

    my $position = $self->getPosition($symbol);
    foreach my $trade (@{ $position->trades }) {
        _writeTempFile 'close', $trade->id . ' ' . $trade->size;
    }
}

sub _empty_hash {
    return {};
}


sub _getPosition {
    my ($self, $symbol) = @_;

    my $position = $self->positions->{$symbol};

    if (!defined($position)) {
        $position = Finance::HostedTrader::Position->new( symbol => $symbol);
        $self->positions->{$symbol} = $position;
    }
    return $position;
}


sub loadPositionsFromYML {
my $self = shift;
my $file = shift;

open( my $fh, $file ) or die $!;
my $content = do { local $/; <$fh> };
close $fh;
my $data = YAML::Syck::Load( $content );
my %positions=();

    $self->{positions} = {};
    foreach my $trade_data (@$data) {
        my $trade = Finance::HostedTrader::Trade->new(
            $trade_data
        );

        my $position = $self->_getPosition($trade->symbol);
        $position->addTrade($trade);
    }
}

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Position>

=cut

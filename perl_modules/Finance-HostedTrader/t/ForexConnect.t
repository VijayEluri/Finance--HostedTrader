#!/usr/bin/perl

use strict;
use warnings;
use Test::More skip_all => 'Flaky tests';#tests => 3;
use Test::Exception;
use Data::Dumper;
use Inline::Java qw(caught);

BEGIN {
    use_ok ('Finance::HostedTrader::Account::FXCM::ForexConnect');
}

my $acc;

throws_ok {
    eval {
        $acc = Finance::HostedTrader::Account::FXCM::ForexConnect->new(
            username => 'bad',
            password => 'reallybad',
            accountType => 'Demo',
        );
    };
    if ($@) {
        if (caught("java.lang.RuntimeException")) {
            die($@->getMessage());
        }
    }
} qr /User or connection doesn't exist./, 'Login failed';

    $acc = Finance::HostedTrader::Account::FXCM::ForexConnect->new(
        username => 'GBD96374001',
        password => '4842',
        accountType => 'Demo',
    );

isa_ok($acc,'Finance::HostedTrader::Account::FXCM::ForexConnect');
    my $positions = $acc->getPositions();
    foreach my $symbol (keys(%{$positions})) {
        $acc->closeTrades($symbol, 'long');
        $acc->closeTrades($symbol, 'short');
    }

    $positions = $acc->getPositions();
    print Dumper(\$positions);

    $acc->openMarket("EURUSD", "long", 10000);
    $positions = $acc->getPositions();
    print Dumper(\$positions);

#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Text::ASCIITable;
use HTML::Table;
use Params::Validate qw(:all);

use Finance::HostedTrader::Factory::Account;
use Finance::HostedTrader::Systems;

my ($address, $port, $class, $format) = ('127.0.0.1', 1500, 'FXCM', 'text');

GetOptions(
    "class=s"   => \$class,
    "address=s" => \$address,
    "port=i"    => \$port,
    "format=s"  => \$format,
);

sub table_factory {
    my %args = validate( @_, {
        format          => 1,
        headingText    => { type => SCALAR, default => undef },
        cols            => { type => ARRAYREF }
    });

    my $t;

    if ($args{format} eq 'text') {
        require Text::ASCIITable;
        $t = Text::ASCIITable->new( { headingText => $args{headingText} } );
        $t->setCols(@{ $args{cols}} );
    } elsif ($args{format} eq 'html') {
        require HTML::Table;
        $t = HTML::Table->new(-head => $args{cols});
    } else {
        die("unknown format: $args{format}");
    }

    return $t;
}

my $account = Finance::HostedTrader::Factory::Account->new( SUBCLASS => $class, address => $address, port => $port)->create_instance();

my $nav = $account->getNav();




my $system = Finance::HostedTrader::Systems->new( name => 'trendfollow', account => $account );

my $positions = $account->getPositions();

my $t = table_factory( format=> $format, headingText => 'Open Positions', cols => ['Symbol', 'Open Date','Size','Entry','Current','PL','%'] );

foreach my $symbol (keys %$positions) {
my $position = $positions->{$symbol};

foreach my $trade (@{ $position->trades }) {
    my $stopLoss = $system->getExitValue($trade->symbol, $trade->direction);
    my $marketPrice = ($trade->direction eq 'short' ? $account->getAsk($trade->symbol) : $account->getBid($trade->symbol));
    my $baseCurrencyPL = $trade->pl;
    my $percentPL = sprintf "%.2f", 100 * $baseCurrencyPL / $nav;

    $t->addRow(
        $trade->symbol,
        $trade->openDate,
        $trade->size,
        $trade->openPrice,
        $marketPrice,
        sprintf('%.2f', $baseCurrencyPL),
        $percentPL
    );
}
}

print "<html><body><p>" if ($format eq 'html');
print "ACCOUNT NAV: " . $nav . "\n\n";
print "</p>" if ($format eq 'html');
print $t;

print "\n";


foreach my $system_name ( qw/trendfollow/ ) {
    my $t = table_factory( format => $format, headingText => $system_name, cols => ['Symbol','Market','Entry','Exit','Direction', 'Worst Case', '%']);
    my $system = Finance::HostedTrader::Systems->new( name => $system_name, account => $account );
    my $data = $system->data;
    my $symbols = $data->{symbols};

    foreach my $direction (qw /long short/) {
        foreach my $symbol (@{$symbols->{$direction}}) {
            my $currentExit = $system->getExitValue($symbol, $direction);
            my $currentEntry = $system->getEntryValue($symbol, $direction);
            my $positionRisk = -1*$system->positionRisk($account->getPosition($symbol));

            $t->addRow( $symbol, 
                        ($direction eq 'long' ? $account->getAsk($symbol) : $account->getBid($symbol)),
                        $currentEntry,
                        $currentExit,
                        $direction,
                        sprintf('%.2f',$positionRisk),
                        sprintf('%.2f',100 * $positionRisk / $nav)
            );
        }
    }
    print $t;
}
print "</body></html>" if ($format eq 'html');

#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 29;
use Test::Exception;
use Data::Dumper;

use Test::MockModule;

BEGIN {
use_ok ('Finance::HostedTrader::Factory::Account');
}
 
my $mockFXCM = new Test::MockModule('Finance::HostedTrader::Account::FXCM');
my $mockMIMELite = new Test::MockModule('MIME::Lite');
my $position;

    my $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS    => 'FXCM',
            address     => '127.0.0.1',
            port        => '1501',
            #notifier    => undef,
    )->create_instance();

    isa_ok($acc,'Finance::HostedTrader::Account::FXCM');

    throws_ok { $acc->getAsk('EURUSD') } qr/Connection refused/, "Exception connecting to FXCM server";
    
    my $pid = fork();
    die("could not fork: $!") if (!defined($pid));
    if ($pid) {
        sleep(2); # Sleep to make sure server process sets itself up
        throws_ok { $acc->getAsk('EURUSD') } qr/Server returned no response/, "Exception when server does not respond to command";
    } else {
        my $sock = IO::Socket::INET->new(
                    Listen    => 1,
                    LocalAddr => 'localhost',
                    LocalPort => 1501,
                    Proto     => 'tcp'
        ) or die($!);
        $sock->accept();
        exit;
    }
    waitpid($pid,0);
    
    $pid = fork();
    die("could not fork: $!") if (!defined($pid));
    if ($pid) {
        sleep(2); # Sleep to make sure server process sets itself up
        throws_ok { $acc->getAsk('EURUSD') } qr/Internal Error: Random error/, "FXCM server throws exception";
    } else {
        my $sock = IO::Socket::INET->new(
                    Listen    => 1,
                    LocalAddr => 'localhost',
                    LocalPort => 1501,
                    Proto     => 'tcp'
        ) or die($!);
        use IO::Select;
        my $paddr = $sock->accept();
        my $select = IO::Select->new($paddr);
        if ( $select->can_read(4) ) {
            print $paddr "500 Random error||THE_END||";
        } else {
            die($!);
        }
        exit;
    }
    waitpid($pid,0);
    
    $pid = fork();
    die("could not fork: $!") if (!defined($pid));
    if ($pid) {
        sleep(2); # Sleep to make sure server process sets itself up
        throws_ok { $acc->getAsk('EURUSD') } qr/Command not found/, "FXCM server returns unrecognized command";
    } else {
        my $sock = IO::Socket::INET->new(
                    Listen    => 1,
                    LocalAddr => 'localhost',
                    LocalPort => 1501,
                    Proto     => 'tcp'
        ) or die($!);
        use IO::Select;
        my $paddr = $sock->accept();
        my $select = IO::Select->new($paddr);
        if ( $select->can_read(4) ) {
            print $paddr "404 gibberish||THE_END||";
        } else {
            die($!);
        }
        exit;
    }
    waitpid($pid,0);
    
    $pid = fork();
    die("could not fork: $!") if (!defined($pid));
    if ($pid) {
        sleep(2); # Sleep to make sure server process sets itself up
        throws_ok { $acc->getAsk('EURUSD') } qr/Unknown return code:/, "FXCM server returns crap";
    } else {
        my $sock = IO::Socket::INET->new(
                    Listen    => 1,
                    LocalAddr => 'localhost',
                    LocalPort => 1501,
                    Proto     => 'tcp'
        ) or die($!);
        use IO::Select;
        my $paddr = $sock->accept();
        my $select = IO::Select->new($paddr);
        if ( $select->can_read(4) ) {
            print $paddr "gibberish";
        } else {
            die($!);
        }
        exit;
    }
    waitpid($pid,0);
    
    $pid = fork();
    die("could not fork: $!") if (!defined($pid));
    if ($pid) {
        sleep(2); # Sleep to make sure server process sets itself up
        is( $acc->getAsk('EURUSD'), "123", "200 code" );
    } else {
        my $sock = IO::Socket::INET->new(
                    Listen    => 1,
                    LocalAddr => 'localhost',
                    LocalPort => 1501,
                    Proto     => 'tcp'
        ) or die($!);
        use IO::Select;
        my $paddr = $sock->accept();
        my $select = IO::Select->new($paddr);
        if ( $select->can_read(4) ) {
            print $paddr "200 123||THE_END||";
        } else {
            die($!);
        }
        exit;
    }
    waitpid($pid,0);
    
    my $sock = IO::Socket::INET->new(
                Listen    => 1,
                LocalAddr => 'localhost',
                LocalPort => 1501,
                Proto     => 'tcp'
    );
    
    diag("Simulating read timeout, will take a bit");
    throws_ok { $acc->getAsk('EURUSD') } qr/Timeout reading from server \(cmd=ask EUR\/USD\)/, "Exception reading from FXCM server";

    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'trades', 'trades command in refreshPositions');
        return '';
    });
    $acc->refreshPositions();

    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        return "-\n  -\n -\n";
    });
    throws_ok { $acc->refreshPositions() } qr/syntax error/, 'Invalid yaml returned from server';


    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'trades', 'trades command');
        return "- symbol: AUDJPY
  id: 6417812
  direction: long
  openPrice: 85.609
  size: 60000
  openDate: 2011-05-06 00:20:26
  pl: 101.75
- symbol: AUDJPY
  id: 6417813
  direction: long
  openPrice: 85.679
  size: 10000
  openDate: 2011-05-06 00:40:26
  pl: 16.94
- symbol: USDJPY
  id: 6378125
  direction: short
  openPrice: 80.563
  size: 60000
  openDate: 2011-05-09 16:55:11
  pl: -275.923
";
    });

    $position = $acc->getPosition('USDJPY');
    is($position->size, -60000, 'shorts are converted to negative size');
    $position = $acc->getPosition('AUDJPY');
    is($position->size, 70000, 'handles multiple trades in a position');

    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'ask EUR/USD', 'Symbol converted in ask command');
    });

    $acc->getAsk('EURUSD');

    throws_ok {$acc->getAsk('rubbish') } qr/Unsupported symbol/, 'Unsupported symbol';

    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'bid EUR/USD', 'Symbol converted in bid command');
    });

    $acc->getBid('EURUSD');

    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        if ($cmd eq 'openmarket EUR/USD long 10000') {
            return "16009151 1.4231"
        } elsif ($cmd eq 'trades') {
            return "- symbol: EURUSD
  id: 16009151
  direction: long
  openPrice: 1.4231
  size: 10000
  openDate: 2011-05-09 16:55:11
  pl: -2.00
";
        } elsif ($cmd eq 'nav') {
            return "50000";
        } else {
            die('unexpected command: ' . $cmd);
        }
    });
    $mockMIMELite->mock('send', sub {
        my $self = shift;

        like($self->{Data}, qr/Open Price: 1.4231/, 'Open Price correct in notification email');
    });
    $acc->openMarket('EURUSD', 'long', '10000', '1.3000');
    $position = $acc->getPosition('EURUSD');
    is($position->size, 10000, 'new position opened');
    is($position->averagePrice, 1.4231, 'new position opened');

    $mockMIMELite->mock('send', sub {
        my $self = shift;

        like($self->{Data}, qr/Close Trade/, 'Close trade notification email');
    });
    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;
        
        if ($cmd eq 'trades') {
            return "- symbol: EURUSD
  id: 16009151
  direction: long
  openPrice: 1.4231
  size: 10000
  openDate: 2011-05-09 16:55:11
  pl: -2.00
";
        } elsif ($cmd eq 'closemarket 16009151 10000') {
            is($cmd, 'closemarket 16009151 10000', 'closemarket command');
        } elsif ($cmd eq 'ask EUR/USD') {
            return "1.4800";
        } elsif ($cmd eq 'nav') {
            return "50000";
        } else {
            die("unknown command: $cmd");
        }

    });
    $acc->closeTrades('EURUSD', 'long');

    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'baseunit AUD/USD', 'Symbol converted in baseunit command');
    });
    $acc->getBaseUnit('AUDUSD');

    $mockFXCM->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'nav', 'nav command');
    });
    $acc->getNav();

    is($acc->getBaseCurrency(), 'GBP', 'getBaseCurrency');

    my $epoch = $acc->getServerEpoch();
    like($epoch, qr/^\d+$/, 'Epoch is numeric');
    ok($epoch > 0, 'Epoch is > 0');

    like($acc->getServerDateTime(), qr/^[12][0-9]{3}-[01][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9]$/, 'DateTime format');

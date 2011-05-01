#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use IO::Select;

    my $sock = IO::Socket::INET->new(
                    PeerAddr => '127.0.0.1',
                    PeerPort => '1500',
                    Proto    => 'tcp',
                    Timeout  => 3,
                    ) or die($!);
    $sock->autoflush(1);
    my $select = IO::Select->new($sock);

    print $sock "trades\n";

    if ($select->can_read(3)) {
        $/="||THE_END||";
        my $data = <$sock>;
        print $data;
    } else {
        print "Timeout\n";
    }

    close($sock);

package Systems;

use strict;
use warnings;

use Config::Any;

sub loadSystem {
    my $file = shift;

    $file = "systems/$file.yml";
    my $system = Config::Any->load_files(
        {
            files => [$file],
            use_ext => 1,
            flatten_to_hash => 1,
        }
    );

    die("failed to load system from $file") unless defined($system);
    return $system->{$file} 
}



1;

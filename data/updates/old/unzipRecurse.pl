#!/usr/bin/perl -w

# here's the File::Find way
use File::Find;
use Cwd;
find(\&findfile, @ARGV); 




sub findfile {

return unless($File::Find::name =~ /\.zip$/);
#print cwd()."name: $_\n";
`unzip '$_'`;
}

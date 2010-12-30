#!/data/wre/prereqs/bin/perl
use strict;

use constant NAGIOS_OK      => 0;
use constant NAGIOS_WARN    => 1;
use constant NAGIOS_CRIT    => 2;
use constant NAGIOS_UNKNOWN => 3;
use DBI;

my $location1       = @ARGV[0];
my $location2       = @ARGV[1];
my $baselineFile    = @ARGV[2];
my $impact          = @ARGV[3] || "0";
#my $nagiosTmpDir = 'http://nagios.bartjol.nl/tmp/';

if (!$location1 || !$location2 || !$baselineFile) {
	print "Not all locations needed for this check are configured\n";
	exit(NAGIOS_WARN);
}

#make a dir with a randomized name to save files in
my $subdir = getId();

my $tmpDir = '/var/www/nagiostempfiles/' . $subdir . '/' ;
system ("mkdir $tmpDir");

my $file1 = $tmpDir . "nagiosCompareFile" . "1";
my $file2 = $tmpDir . "nagiosCompareFile" . "2";
my $diffFile = $tmpDir . 'nagiosCompareDiffFile.txt';
my $diffFile2 = $tmpDir . 'nagiosCompareDiffFile2.txt';

# the variables below are for possible scp use
#my $user = 'root';
#my $password = 'secret';
#my $hostname = 'localhost';

# get the files, diff them and determine the length of the diff file
system ("wget -qNO $file1 $location1");
system ("wget -qNO $file2 $location2");
system ("diff $file1 $file2 > $diffFile");

my $compareResult = `diff $diffFile $baselineFile`;
system ( "diff $diffFile $baselineFile > $diffFile2");

if (length($compareResult) eq "0") {
    print("Compared files are below thresshold differences");
#    system ("rm -r $tmpDir");
    exit(NAGIOS_OK);
}
elsif ($impact eq "0") {
    print("Compared files differ too much");
#    system ("rm -r $tmpDir");
    exit(NAGIOS_WARN)|$compareResult;
}
elsif ($impact ne "0") {
    print("Compared files differ too much");
#    system ("rm -r $tmpDir");
    exit(NAGIOS_CRIT);
}
else {
    exit(NAGIOS_UNKNOWN);
}

# a sub to make a randomized dir to save files
sub getId {
my $id;
my $_rand;

my $idLength = 22;

my @chars = split(" ",
    "a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9");

srand;

for (my $i=0; $i <= $idLength ;$i++) {
    $_rand = int(rand 62);
    $id .= $chars[$_rand];
}
return $id;
}

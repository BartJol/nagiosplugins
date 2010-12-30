#!/data/wre/prereqs/bin/perl
use strict;

#use constant NAGIOS_OK      => 0;
#use constant NAGIOS_WARN    => 1;
#use constant NAGIOS_CRIT    => 2;
#use constant NAGIOS_UNKNOWN => 3;
my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);
use DBI;

my $location1       = @ARGV[0];
my $location2       = @ARGV[1];
my $baselineFile    = @ARGV[2] || "";
my $impact          = @ARGV[3] || "warn";

if (!$location1 || !$location2 || !$baselineFile) {
	print "Not all locations needed for this check are configured\n";
	exit $ERRORS{"WARNING"};
}

open(baseline, $baselineFile) or die "An existing baseline file is required";

#make a dir with a randomized name to save files in
my $subdir = getId();

my $tmpDir = '/tmp/' . $subdir . '/' ;
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

$compareResult =~ s/\n/\<br \/\>/g;

if (length($compareResult) eq "0") {
    print("Compared files are below thresshold differences");
    system ("rm -r $tmpDir");
    exit $ERRORS{"OK"};
}
elsif ($impact eq "warn") {
    print("Compared files differ too much");
    system ("rm -r $tmpDir");
    (defined($compareResult)) ?  print " | ",$compareResult,"\n" : print "\n";
     exit $ERRORS{"WARNING"};

}
elsif ($impact eq "crit") {
    print("Compared files differ too much");
    system ("rm -r $tmpDir");
    (defined($compareResult)) ?  print " | ",$compareResult,"\n" : print "\n";
    exit $ERRORS{"CRITICAL"};
}
else {
    exit $ERRORS {"UNKNOWN"};
}

# a sub to make a randomized dir to save files
sub getId {
my $id;
my $_rand;

my $idLength = 22;

my @chars = (0..9, "a".."z", "A".."Z");

srand;

for (my $i=0; $i <= $idLength ;$i++) {
    $_rand = int(rand 62);
    $id .= $chars[$_rand];
}
return $id;
}

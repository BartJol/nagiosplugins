#!/data/wre/prereqs/bin/perl
use strict;

=head1 NAME

check_compare_files.pl script

=head1 DESCRIPTION

This script is intended for nagios. It retrieves 2 files with wget, compares them with the diff command line tool. The result
is compared with a baseline file, again with diff. The result of the last comparison can be found in the
Performance data field in Nagios.
The script needs write access in /tmp/

=head2 process

this is run as a script of the command line with 3 rquired arguments and 1 optional argument:
./check_compare_files.pl file1 file2 baselinefile [impact]

=over 4

=item file1

The location of the first file to compare. Should be valid for wget

=item file2

The location of the second file to compare. Should be valid for wget

=item baselinefile

The location in the filesystem of an file created like:
diff file1 file2 > baslinefile

=item impact

Default the impact factor is warn. A factor "crit" can be declared here to make the nagios output be Critical.

=back

=cut


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

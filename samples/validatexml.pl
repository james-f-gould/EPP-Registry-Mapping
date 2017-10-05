#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long;

my $keep = 0;
my @detokenizedFilesToDelete;

sub usage {
	printf "Usage: $0 [-delete] (<file>.xml|<file>.token)+\n";
	printf "-keep Keeps the generated de-tokenized files.  The default is to delete the generated de-tokenized files.\n";
	printf "Each .token file will be de-tokenized to a file without the .token extension prior to validation.\n";
	exit;
}

sub detokenizeFile {
	my ($tokenizedFile, $detokenizedFile) = @_;
	
	open(my $inFh, '<:encoding(UTF-8)', $tokenizedFile) || die "Could not open tokenized file '$tokenizedFile' $!";
	open(my $outFh, '>:encoding(UTF-8)', $detokenizedFile) || die "Could not create detokenized file '$detokenizedFile' $!";
	
	while (my $line = <$inFh>) {
		if ($line =~ /\&(\S+)\;/) {
			my $tokenFile = $1;
			open(my $tokenFh, '<:encoding(UTF-8)', $tokenFile) || die "Could not open token file '$tokenFile' $!";
			while (<$tokenFh>) {
			   print $outFh $_;
			}
			close $tokenFh;			
		}
		else {
			print $outFh $line;
		}
	}

	close $inFh;
	close $outFh;
}

sub detokenizeFiles {
	my @detokenizedFiles;
	my @suffixList = qw(.xml .xml.token);
	my $sourceFile;
	
	foreach $sourceFile (@_) {
	
		my ($name, $dir, $ext) = fileparse($sourceFile, @suffixList);
		
		if ($ext eq '.xml') {
			push(@detokenizedFiles, $sourceFile);
		}
		elsif ($ext eq '.xml.token') {
			my $detokenizedFile = "$dir/$name.xml";
			detokenizeFile($sourceFile, $detokenizedFile);
		
			push (@detokenizedFiles, $detokenizedFile);
			
			if (!$keep) {
				push(@detokenizedFilesToDelete, $detokenizedFile); 
			}
		}
		else {
			die "Invalid extension $ext for file $sourceFile";
		}
	}
	
	return @detokenizedFiles;
}


sub main {
	if ($#ARGV == -1) {
		usage();
	};
	
	GetOptions ("keep" => \$keep) || die "Error parsing command line arguments\n";
	
	my @files = detokenizeFiles(@ARGV);
	
	system("../xmlvalidator-1.0/xmlvalidator -schemasDir . -schemasFile xmlschemas.txt @files");
	
	if (!$keep) {
		unlink @detokenizedFilesToDelete;
	}
}


main();


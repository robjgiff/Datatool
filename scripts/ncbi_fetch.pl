#!/usr/bin/env perl
use strict;
use LWP::Simple;

#declare global variables and initialize them if necessary
use vars qw|%OPTs %KEYs $utils|;
$utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";

%OPTs = ();
%KEYs =
  ( '-d' => 'database', '-q' => 'query', '-r' => 'report', '-o' => 'output' );
&main();

sub main {
	&parse_args;
	&process;
	exit(0);
}

# define your process core here
sub process {
	my $db      = $OPTs{database};
	my $query   = $OPTs{query};
	my $report  = $OPTs{report};
	my $esearch = "$utils/esearch.fcgi?" . "db=$db&retmax=1&usehistory=y&term=";
	my $esearch_result = get( $esearch . $query );
	print "\nESEARCH RESULT: $esearch_result\n";
	$esearch_result =~
m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;
	my $Count    = $1;
	my $QueryKey = $2;
	my $WebEnv   = $3;
	print "Count = $Count; QueryKey = $QueryKey; WebEnv = $WebEnv\n";

   # ---------------------------------------------------------------------------
   # this area defines a loop which will display $retmax citation results from
   # Efetch each time the the Enter Key is pressed, after a prompt.

	my $retstart;
	my $retmax = 100;
	my $ofh = openFileRW($OPTs{output}, 'w');

	for ( $retstart = 0 ; $retstart < $Count ; $retstart += $retmax ) {
		my $efetch =
		    "$utils/efetch.fcgi?"
		  . "rettype=$report&retmode=text&retstart=$retstart&retmax=$retmax&"
		  . "db=$db&query_key=$QueryKey&WebEnv=$WebEnv";

		print "\nEF_QUERY=$efetch\n";

		my $efetch_result = get($efetch);

		print "---------\nEFETCH RESULT("
		  . ( $retstart + 1 ) . ".."
		  . ( $retstart + $retmax ) . "): ";
		print $ofh $efetch_result;
		sleep 5;
	}
}

sub openFileRW {
	use FileHandle;
	my ( $filename, $mode ) = @_;
	$mode ||= 'r';
	my $mode_desc = $mode eq 'r' ? 'writing' : 'reading';
	my $fh = new FileHandle( $filename, $mode );
	unless ( defined $fh ) {
		die "Can't open $filename for $mode_desc $!\n";
	}
	return $fh;
}

sub usage {
	my ( $msg, $prompt );
	$msg = $_[0];
	( $prompt = $0 ) =~ s|.*\/||;
	foreach my $k ( keys %KEYs ) {
		$prompt .= ' ' . $k . ' ' . $KEYs{$k};
	}
	die <<DEADMSG;
  	#==================================================================#
  	# File:ncbi_fetch.pl                                               #
	# Author: Chunlin Wang (wangcl\@stanford.edu)                       #  
	# Date: May 29, 2007                                               #
	# The piece of code is provided as it is, so use it with caution.  #
	#==================================================================#
	# Example ./ncbi_fetch.pl -r gb -q "Hepatitis C Virus"[Organism] -o HCV_all_genbank.gb -d Nucleotide
	
  	$prompt

DEADMSG
}

sub parse_args {

	#provide your default values here
	#$OPTs{'default_key'} = 'default_value'
	for ( my $i = 0 ; $i < $#ARGV ; $i++ ) {
		$OPTs{ $KEYs{ $ARGV[$i] } } = $ARGV[ $i + 1 ]
		  if defined $KEYs{ $ARGV[$i] };
	}
	for my $k ( values %KEYs ) {
		usage( $k . ' not provided' ) unless defined $OPTs{$k};
	}
}

#!/usr/bin/perl -w
############################################################################
# Script:      trackwrangler.pl 
# Description: utility script for converting various track files to 
#              a consistent format
# History:     Version 1.0 Creation: Rob J Gifford 2016
############################################################################

############################################################################
# Import statements/packages (externally developed packages)
############################################################################
use strict;
use Getopt::Long;

############################################################################
# Globals
############################################################################

# Initialise usage statement to print if usage is incorrect
my($USAGE) = "\t# Usage: trackwrangler.pl -m=[mode] -i=[infile]\n\n";
my $console_width = 70; # assumed width of the console
my $version_num = '(version 1.0)';

############################################################################
# Main program
############################################################################

show_title();
main(); # Run script
exit; # Exit program

#***************************************************************************
# Subroutine:  main
# Description: top level handler fxn
#***************************************************************************(
sub main {

	# Read in options using GetOpt::Long
	my $infile       = undef;
	my $mode		 = undef;
	my $name		 = undef;
	my $help		 = undef;
	
	GetOptions ('infile|i=s'  => \$infile, 
				'mode|m=i'    => \$mode,
				'name|n=s'    => \$name,
			    'help'        => \$help,
	) or die $USAGE;

	if ($help) { 
		show_help_page(); # Show help page
		exit;
	}
	
	if ($mode) { 
		unless ($infile) { 
			print "\t# No infile was specified\n\n";
			die $USAGE; 
		}	
	
		if ($mode eq 1) { # RepBase
			create_loci_file_repbase($infile);
		}
		elsif ($mode eq 2) {
			create_loci_file_retrotector($infile);
		}
		elsif ($mode eq 3) {
			unless ($name) {
				print "\n\t # this option requires a value for the track name -n=[name] \n\n\n";
				exit;
			}
			create_loci_file_digs($infile, $name);
		}
		elsif ($mode eq 4) {
			create_loci_file_coffin($infile);
		}		
		elsif ($mode eq 5) {
			convert_blomberg_2($infile);
		}		
		else {
			show_help_page(); # Show help page
			print "\n\t # No option '$mode' for mode\n\n\n";
			exit;
		}
		
	}
	else {
		print "\t# No infile was specified\n\n";
		die $USAGE; 
	}	
}

############################################################################
# PROCESSING RAW ANNOTATIONS INTO STANDARD ERV TRACKS
############################################################################

#***************************************************************************
# Subroutine:  create_loci_file_repbase
# Description: generate names using a track in the RepBase format
#***************************************************************************
sub create_loci_file_repbase {

	my ($infile) = @_;

	print "\n\t Applying the Missillac nomeclature to REPBASE-formatted track";
	sleep 1;

	my @output;
	
	# Read the file 
	my @raw_file;
	read_file($infile, \@raw_file);
	my $lines = scalar @raw_file;
	unless ($lines) {
		die "\n\t Unable to read infile '$infile'\n\n";
	}
	elsif ($lines eq 1) {
		print "\n\t Single line of data was read form infile '$infile'";
		die "\n\t Check line break formatting\n\n";
	}

	# Remove the header line
	my $header_line = shift @raw_file;

	# Process the file line by line
	my $erv_number = 0;
	shift @raw_file;
	my $i = '0';
	my $line_number = '0';
	foreach my $line (@raw_file) {

		chomp $line; # remove newline
		my @line = split(" ", $line);
		my $j = '0';
		$line_number++;
		
		#foreach my $element (@line) {
		#	print "\n\t ELEMENT $j : $element";
		#	$j++;
		#}
		#die;
				
		# Get the data from the line 
		my $genoName2 = $line[5];
		my $first     = $line[6];
		my $second    = $line[7];
		my $genoLeft  = $line[8];
		my $repName   = $line[10];
		my $repClass  = $line[11];
		my $repFamily = $line[12];

		# Deal with orientation issues
		my $end;
		my $start;
		my $orientation;
		if ($first < $second) {
			$orientation = 'positive';
			$start = $first;
			$end   = $second;
		}
		elsif ($second < $first) {
			$orientation = 'negative';
			$start = $second;
			$end   = $first;
		}
		
		# Only deal with LTR elements
		unless ($repClass eq 'LTR') {
			print "\n\t $repClass\n\n";
			next;
		}
		# Exclude MaLRs
		if ($repFamily =~ 'MaLR') {
			next;
		}
		# Exclude Gypsy-like
		if ($repFamily =~ 'Gypsy') {
			next;
		}
		#die;
	
	
		# Get genome region	
		my $genome_region;
		if ($repName =~ '-int') {	
			my @repName = split ("-", $repName);
			$repName = shift @repName;
			$genome_region = 'int';		
		}
		else {	
			$genome_region = 'LTR';		
		}			
			
		# Create the reformatted line
		$i++;
		my $new_line = "RepBase\tHomo sapiens\thg19\t$repName\t$genoName2\t$start\t$end\t$orientation\t$genome_region\t$repFamily\n";
		print "LINE $i: $new_line";
		push (@output, $new_line);
	}

	# Write the output
	my $outfile = $infile . '.converted.txt';
	write_file($outfile, \@output)

}

#***************************************************************************
# Subroutine:  create_loci_file_retrotector
# Description: generate names using a track in RetroTector format
#***************************************************************************
sub create_loci_file_retrotector {

	my ($infile) = @_;

	print "\n\t Applying the Missillac nomeclature to RETROTECTOR-formatted track";
	sleep 1;

	my @output;

	# Read the file 
	my @raw_file;
	read_file($infile, \@raw_file);
	my $lines = scalar @raw_file;
	unless ($lines) {
		die "\n\t Unable to read infile '$infile'\n\n";
	}
	elsif ($lines eq 1) {
		print "\n\t Single line of data was read form infile '$infile'";
		die "\n\t Check line break formatting\n\n";
	}

	# Remove the header line
	my $header_line = shift @raw_file;

	# Process the file line by line
	my $erv_number = 0;
	foreach my $line (@raw_file) {

		chomp $line; # remove newline
		#print "\n\t LINE: $line"; exit;

		my @line = split("\t", $line); # Split on tabs
	
		# Get the data from the line 		
		my $taxorder   = $line[0];
		my $rvnr       = $line[1];
		my $subgenes   = $line[2];
		my $chr        = $line[3];
		my $chainstart = $line[4];
		my $chainend   = $line[5];
		my $chaingenus = $line[6];
		my $breaks     = $line[7];
		my $ltr5pos1   = $line[8];
		my $ltrdiv     = $line[9];
		my $pbsscore   = $line[10];
		my $pbstype    = $line[11];
		my $pbsseqrete = $line[12];
		my $bestpbstyp = $line[13];
		my $bestpbscod = $line[14];
		my $likelypseq = $line[15];
		my $likelypbs  = $line[16];
		my $likelypcod = $line[17];
		my $gagpos1    = $line[18];
		my $bestrefrv  = $line[55];
		my $polclass   = $line[56];

		my $noncanon   = $line[58];		
		my $canon      = $line[59];
		my $supergroup = $line[60];

		my $class      = $line[61];				
		my $joined = "$canon" . '_' . $supergroup . '_' . $class;
		
		# Various ways to generate a unique id
		$erv_number++; # Increment counter by one
		my $id = $erv_number;

		# Assign the group part of the name
		my $name;
		if ($canon) {
			$name = $canon;
		}
		elsif ($noncanon) {
			$name = $noncanon;		
		}
		else { 
			$name = $supergroup;
		}
		
		# Create the locus name
		my $locus_name = normalize_names($name, 'RetTec');
		
		$chr = 'chr' . $chr;
		$chr =~ s/ //g;

		$subgenes =~ s/ /-/g;
		
		my $new_line = "RetTec\t$locus_name\t$chr\t$chainstart\t$chainend\t$subgenes\n";
		push (@output, $new_line);
	}

	# Write the output
	my $outfile = $infile . '.missillac.txt';
	write_file($outfile, \@output)
}

#***************************************************************************
# Subroutine:  create_loci_file_digs
# Description: generate names using a track obtained via DIGS
#***************************************************************************
sub create_loci_file_digs {

	my ($infile, $track_name) = @_;

	print "\n\t Applying the Missillac nomeclature to DIGS-formatted track";
	sleep 1;

	my @output;

	# Read the file 
	my @raw_file;
	read_file($infile, \@raw_file);
	my $lines = scalar @raw_file;
	unless ($lines) {
		die "\n\t Unable to read infile '$infile'\n\n";
	}
	elsif ($lines eq 1) {
		print "\n\t Only one  line of text was read from infile '$infile'";
		print "\n\t Check line break formatting\n\n"; exit;
	}

	# Remove the header line
	#my $header_line = shift @raw_file;

	# Process the file line by line
	my $erv_number = 0;
	foreach my $line (@raw_file) {
	
		chomp $line; # remove newline
		#print "\n\t LINE: $line"; exit;

		my @line = split("\t", $line); # Split on tabs
				
		# Get the data from the line 
		# (note this assumes a certain column order)
		# Organism	Version	Target_name	Scaffold	Orientation	Assigned_name	Extract_start	Extract_end	Genome_structure
		my $organism      = $line[0];
		my $version       = $line[1];
		my $chunk_name    = $line[2];
		my $orientation   = $line[3];
		my $erv_name      = $line[4];
		my $extract_start = $line[5];
		my $extract_end   = $line[6];
		my $gene          = $line[7];
		#print "\n\t ## GENE: $gene";

		# Various ways to generate a unique id
		$erv_number++; # Increment counter by one
		my $id = $erv_number;

		# Assign start and end based on orientation
		my $start;
		my $end;
		if ($orientation eq '-') {
			$start = $extract_end;
			$end   = $extract_start;		
		}
		else {
			$start = $extract_start;		
			$end = $extract_end;
		}

		# Create the locus name
		my $locus_name = normalize_names($erv_name, $track_name);

		my $new_line = "$track_name\t$locus_name\t$chunk_name\t$start\t$end\t$gene\n";
		push (@output, $new_line);

	}
}

#***************************************************************************
# Subroutine:  convert_blomberg_2
# Description: 
#***************************************************************************
sub convert_blomberg_2 {

	my ($infile, $track_name) = @_;

	print "\n\t Applying the Missillac nomeclature to DIGS-formatted track";
	sleep 1;

	my @output;

	# Read the file 
	my @raw_file;
	read_file($infile, \@raw_file);
	my $lines = scalar @raw_file;
	unless ($lines) {
		die "\n\t Unable to read infile '$infile'\n\n";
	}
	elsif ($lines eq 1) {
		print "\n\t Only one  line of text was read from infile '$infile'";
		print "\n\t Check line break formatting\n\n"; exit;
	}

	# Process the file line by line
	my $erv_number = 0;
	foreach my $line (@raw_file) {
	
		chomp $line; # remove newline
		my @line = split("\t", $line); # Split on tabs
				
		# Get the data from the line 
		my $first  = $line[3];
		my $second = $line[4];

		my $orientation;
		my $end;
		my $start;
		if ($first < $second) {
			$orientation = 'positive';
			$start = $first;
			$end   = $second;
		}
		elsif ($second < $first) {
			$orientation = 'negative';
			$start = $second;
			$end   = $first;
		}
		
		my $new_line = "$start\t$end\t$orientation\n";
		#print "\n\t $new_line  ORIENT: '$orientation'";
		push (@output, $new_line);
		
	}

	# Write the output
	my $outfile = $infile . '.translated.txt';
	write_file($outfile, \@output)


}



############################################################################
# Name translation to standard 
############################################################################

#***************************************************************************
# Subroutine:  normalize_names
# Description: self explanatory
#***************************************************************************
sub normalize_names {

	my ($erv_name, $track_name) = @_;

	# Translate

	my $normalized_name = undef;
	
	# RetTec translation
	if ($track_name eq 'RetTec') {
	
		if    ($erv_name eq 'HERVT')  { $normalized_name = 'ERV.T'; }
		elsif ($erv_name eq 'HERVE')  { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV1')  { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV3')  { $normalized_name = 'ERV.R(b)'; }
		elsif ($erv_name eq 'HERVFRD') { $normalized_name = 'ERV.R(b)'; }
		elsif ($erv_name eq 'HERVH')   { $normalized_name = 'ERV.H'; }
		elsif ($erv_name eq 'HERVFA')  { $normalized_name = 'ERV.F(a)'; }
		elsif ($erv_name eq 'HERVFB')  { $normalized_name = 'ERV.F(b)'; }
		elsif ($erv_name eq 'HERVFC')  { $normalized_name = 'ERV.F(c)'; }
		elsif ($erv_name eq 'HERV9')   { $normalized_name = 'ERV.9'; }
		elsif ($erv_name eq 'HERVW')   { $normalized_name = 'ERV.W'; }
		elsif ($erv_name eq 'HERVIP')  { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERVADP') { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'MER65')   { $normalized_name = 'ERV.L(b)'; }
		elsif ($erv_name eq 'HML1')    { $normalized_name = 'ERV.K(HML1)'; }
		elsif ($erv_name eq 'HML2')    { $normalized_name = 'ERV.K(HML2)'; }
		elsif ($erv_name eq 'HML3')    { $normalized_name = 'ERV.K(HML3)'; }
		elsif ($erv_name eq 'HML4')    { $normalized_name = 'ERV.K(HML4)'; }
		elsif ($erv_name eq 'HML5')    { $normalized_name = 'ERV.K(HML5)'; }
		elsif ($erv_name eq 'HML6')    { $normalized_name = 'ERV.K(HML6)'; }
		elsif ($erv_name eq 'HML7')    { $normalized_name = 'ERV.K(HML7)'; }
		elsif ($erv_name eq 'HML8')    { $normalized_name = 'ERV.K(HML8)'; }
		elsif ($erv_name eq 'HML9')    { $normalized_name = 'ERV.K(HML9)'; }
		elsif ($erv_name eq 'HML10')   { $normalized_name = 'ERV.K(HML10)'; }
		elsif ($erv_name eq 'HERVL')   { $normalized_name = 'ERV.L'; }
		elsif ($erv_name eq 'HERVS')   { $normalized_name = 'ERV.S'; }
		elsif ($erv_name eq 'HERV1ARTIODACT') { $normalized_name = 'ERV.R(b)'; }
		else                           { $normalized_name = $erv_name; }
	}
	
	# Tristem translation
	if ($track_name eq 'Tristem') {
		   if ($erv_name eq 'HERV.S71') { $normalized_name = 'ERV.T'; }
		elsif ($erv_name eq 'HERV.E')   { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV.R')   { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'RRHERV.I') { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV.R(type_b)') { $normalized_name = 'ERV.R(b)'; }
		elsif ($erv_name eq 'HERV.FRD') { $normalized_name = 'ERV.R(b)'; }
		elsif ($erv_name eq 'HERV.H')   { $normalized_name = 'ERV.H'; }
		elsif ($erv_name eq 'HERV.F')   { $normalized_name = 'ERV.F(a)'; }
		elsif ($erv_name eq 'HERV.F(type_b)')  { $normalized_name = 'ERV.F(b)'; }
		elsif ($erv_name eq 'HERV.XA')  { $normalized_name = 'ERV.F(b)'; }
		elsif ($erv_name eq 'HERV.P')   { $normalized_name = 'ERV.P'; }
		elsif ($erv_name eq 'HERV.9')   { $normalized_name = 'ERV.9'; }
		elsif ($erv_name eq 'HERV.W')   { $normalized_name = 'ERV.W'; }
		elsif ($erv_name eq 'HERV.I')   { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERV.IP')  { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERV.ADP') { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERV.HS49C23')  { $normalized_name = 'ERV.L(b)'; }
		elsif ($erv_name eq 'HERV.K(HML-1)')    { $normalized_name = 'ERV.K(HML1)'; }
		elsif ($erv_name eq 'HERV.K(HML-2)')    { $normalized_name = 'ERV.K(HML2)'; }
		elsif ($erv_name eq 'HERV.K(HML-3)')    { $normalized_name = 'ERV.K(HML3)'; }
		elsif ($erv_name eq 'HERV.K(HML-4)')    { $normalized_name = 'ERV.K(HML4)'; }
		elsif ($erv_name eq 'HERV.K(HML-5)')    { $normalized_name = 'ERV.K(HML5)'; }
		elsif ($erv_name eq 'HERV.K(HML-6)')    { $normalized_name = 'ERV.K(HML6)'; }
		elsif ($erv_name eq 'HERV.K(HML-7)')    { $normalized_name = 'ERV.K(HML7)'; }
		elsif ($erv_name eq 'HERV.K(HML-8)')    { $normalized_name = 'ERV.K(HML8)'; }
		elsif ($erv_name eq 'HERV.K(HML-9)')    { $normalized_name = 'ERV.K(HML9)'; }
		elsif ($erv_name eq 'HERV.K(HML-10)')   { $normalized_name = 'ERV.K(HML10)'; }
		elsif ($erv_name eq 'HERV.L')   { $normalized_name = 'ERV.L'; }
		elsif  ($erv_name eq 'HERV.S')  { $normalized_name = 'ERV.S'; }
		#if    ($erv_name eq 'HERV-Z89907?}
		else                            { $normalized_name = $erv_name; }

	}

	# Heidmann translation
	if ($track_name eq 'Heidmann') {
		if    ($erv_name eq 'HERV-S71') { $normalized_name = 'ERV.T'; }
		elsif ($erv_name eq 'HERV-E')   { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV-R')   { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'RRHERV.I') { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV-R(type_b)') { $normalized_name = 'ERV.R(b)'; }
		elsif ($erv_name eq 'HERV-FRD') { $normalized_name = 'ERV.R(b)'; }
		elsif ($erv_name eq 'HERV-H')   { $normalized_name = 'ERV.H'; }
		elsif ($erv_name eq 'HERV-F')   { $normalized_name = 'ERV.F(a)'; }
		elsif ($erv_name eq 'HERV-XA')  { $normalized_name = 'ERV.F(b)'; }
		elsif ($erv_name eq 'HERV-P')   { $normalized_name = 'ERV.P'; }
		elsif ($erv_name eq 'ERV-9')    { $normalized_name = 'ERV.9'; }
		elsif ($erv_name eq 'HERV-W')   { $normalized_name = 'ERV.W'; }
		elsif ($erv_name eq 'HERV-I')   { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERV-IP')  { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERV-ADP') { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERV-HS49C23')  { $normalized_name = 'ERV.L(b)'; }
		elsif ($erv_name eq 'HML1')     { $normalized_name = 'ERV.K(HML1)'; }
		elsif ($erv_name eq 'HML2')     { $normalized_name = 'ERV.K(HML2)'; }
		elsif ($erv_name eq 'HML-3')    { $normalized_name = 'ERV.K(HML3)'; }
		elsif ($erv_name eq 'HML4')     { $normalized_name = 'ERV.K(HML4)'; }
		elsif ($erv_name eq 'HML5')     { $normalized_name = 'ERV.K(HML5)'; }
		elsif ($erv_name eq 'HML6')     { $normalized_name = 'ERV.K(HML6)'; }
		elsif ($erv_name eq 'HML7')     { $normalized_name = 'ERV.K(HML7)'; }
		elsif ($erv_name eq 'HML8')     { $normalized_name = 'ERV.K(HML8)'; }
		elsif ($erv_name eq 'HML9')     { $normalized_name = 'ERV.K(HML9)'; }
		elsif ($erv_name eq 'HML10')    { $normalized_name = 'ERV.K(HML10)'; }
		elsif ($erv_name eq 'HERV-L')   { $normalized_name = 'ERV.L'; }
		elsif ($erv_name eq 'HERV-S')   { $normalized_name = 'ERV.S'; }
		#if    ($erv_name eq 'HERV-Z89907?}
		else                            { $normalized_name = $erv_name; }

	}

	# Gifford translation
	if ($track_name eq 'Gifford') {

		if    ($erv_name eq 'HERV-T')        { $normalized_name = 'ERV.T'; }
		elsif ($erv_name eq 'HERV-E')        { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV-R')        { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV-R(b)')     { $normalized_name = 'ERV.R(b)'; }
		elsif ($erv_name eq 'HERV-H')        { $normalized_name = 'ERV.H'; }
		elsif ($erv_name eq 'HERV-Fb')       { $normalized_name = 'ERV.F(b)'; }
		elsif ($erv_name eq 'HERV-XA')       { $normalized_name = 'ERV.F(b)'; }
		elsif ($erv_name eq 'ERV-F(c)')      { $normalized_name = 'ERV.F(c)'; }
		elsif ($erv_name eq 'HERV-P')        { $normalized_name = 'ERV.P'; }
		elsif ($erv_name eq 'ERV-9')         { $normalized_name = 'ERV.9'; }
		elsif ($erv_name eq 'HERV-W')        { $normalized_name = 'ERV.W'; }
		elsif ($erv_name eq 'HERV-I')        { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERV-I')        { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERV-Lb')       { $normalized_name = 'ERV.L(b)'; }
		elsif ($erv_name eq 'HERV-K-HML1')   { $normalized_name = 'ERV.K(HML1)'; }
		elsif ($erv_name eq 'HERV-K-HML2')   { $normalized_name = 'ERV.K(HML2)'; }
		elsif ($erv_name eq 'HERV-K-HML2-K110')   { $normalized_name = 'ERV.K(HML2)'; }
		elsif ($erv_name eq 'HERV-K-HML3')   { $normalized_name = 'ERV.K(HML3)'; }
		elsif ($erv_name eq 'HERV-K-HML4')   { $normalized_name = 'ERV.K(HML4)'; }
		elsif ($erv_name eq 'HERV-K-HML5')   { $normalized_name = 'ERV.K(HML5)'; }
		elsif ($erv_name eq 'HERV-K-HML6')   { $normalized_name = 'ERV.K(HML6)'; }
		elsif ($erv_name eq 'HERV-K-HML7')   { $normalized_name = 'ERV.K(HML7)'; }
		elsif ($erv_name eq 'HERV-K-HML8')   { $normalized_name = 'ERV.K(HML8)'; }
		elsif ($erv_name eq 'HERV-K-HML9')   { $normalized_name = 'ERV.K(HML9)'; }
		elsif ($erv_name eq 'HERV-K-14C')    { $normalized_name = 'ERV.K(HML9)'; }
		elsif ($erv_name eq 'HERV-K-HML10)') { $normalized_name = 'ERV.K(HML10)'; }
		elsif ($erv_name eq 'HERV-L')        { $normalized_name = 'ERV.L'; }
		elsif ($erv_name eq 'HERV-S')        { $normalized_name = 'ERV.S'; }
		elsif ($erv_name eq 'HERV-U3')       { $normalized_name = 'ERV.U3'; }
		else                                 { $normalized_name = $erv_name; }
	}
	
	# RepBase translation
	if ($track_name eq 'RepBase') {

		# Internals
		if    ($erv_name eq 'HERVS71')         { $normalized_name = 'ERV.T'; }
		elsif ($erv_name eq 'HERVE_a-int')     { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERVE_a-int')     { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV1')           { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'HERV3')           { $normalized_name = 'ERV.E'; }
		elsif ($erv_name eq 'ERV3-1-i')        { $normalized_name = 'ERV.R(b)'; }				
		elsif ($erv_name eq 'HERVH48')         { $normalized_name = 'ERV.H'; }
		elsif ($erv_name eq 'HERVFH19')        { $normalized_name = 'ERV.F(a)'; }
		elsif ($erv_name eq 'HERVFH21')        { $normalized_name = 'ERV.F(b)'; }
		elsif ($erv_name eq 'HERV46I')         { $normalized_name = 'ERV.F(c)'; }
		elsif ($erv_name eq 'HERV9')           { $normalized_name = 'ERV.9'; }
		elsif ($erv_name eq 'HERV17')          { $normalized_name = 'ERV.W'; }
		elsif ($erv_name eq 'HERVIP')          { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'HERVP71A_1')      { $normalized_name = 'ERV.I'; }
		elsif ($erv_name eq 'MER65')           { $normalized_name = 'ERV.L(b)'; }
		elsif ($erv_name eq 'HERVK14I')        { $normalized_name = 'ERV.K(HML1)'; }
		elsif ($erv_name eq 'HERVK')           { $normalized_name = 'ERV.K(HML2)'; }
		elsif ($erv_name eq 'HERVK9I')         { $normalized_name = 'ERV.K(HML3)'; }
		elsif ($erv_name eq 'HERVK13I')        { $normalized_name = 'ERV.K(HML4)'; }
		elsif ($erv_name eq 'HERVK22')         { $normalized_name = 'ERV.K(HML5)'; }
		elsif ($erv_name eq 'HERVK31')         { $normalized_name = 'ERV.K(HML6)'; }
		elsif ($erv_name eq 'HERVK11DI')       { $normalized_name = 'ERV.K(HML7)'; }
		elsif ($erv_name eq 'HERVK11I')        { $normalized_name = 'ERV.K(HML8)'; }
		elsif ($erv_name eq 'HERVK14C')        { $normalized_name = 'ERV.K(HML9)'; }
		elsif ($erv_name eq 'HERVKC4)')        { $normalized_name = 'ERV.K(HML10)'; }
		elsif ($erv_name eq 'HERVL')           { $normalized_name = 'ERV.L'; }
		elsif ($erv_name eq 'HERVS')           { $normalized_name = 'ERV.S'; }
		elsif ($erv_name eq 'HERV18')          { $normalized_name = 'ERV.S'; }
		else                                   { $normalized_name = undef; }	
		if ($normalized_name) {

		}
	}

	#print "\n\t '$erv_name' \t '$normalized_name'";
	return $normalized_name;
}

#***************************************************************************
# Subroutine:  load_translations
# Description: load translation tables
#***************************************************************************
sub load_translations {

	my ($translations_path, $translations_ref) = @_;

	# Read translation from file
	unless ($translations_path) { die; }
	my @file;
	read_file($translations_path, \@file);
	my $header = shift @file;
	chomp $header;
	my @header = split("\t", $header); 
	my %levels;
	my $i = 0;
	foreach my $element (@header) {
		$i++;
		$levels{$i} = $element;
	}

	# Set up the translations
	foreach my $line (@file) {

		chomp $line;
		my @line  = split("\t", $line);
		my $j = 0;
		my %taxonomy;
		foreach my $value (@line) {
			$j++;
			my $level = $levels{$j};
			unless ($level) { die; }		
			$taxonomy{$level} = $value;			
		}
		my $id = shift @line;
		$translations_ref->{$id} = \%taxonomy;		
	}
}

############################################################################
# Basic functions (IO, console interaction etc)
############################################################################

#***************************************************************************
# Subroutine:  read_file
# Description: read an input file to an array
# Arguments:   $file: the name of the file to read
#              $array_ref: array to copy to
#***************************************************************************
sub read_file {

	my ($file, $array_ref) = @_;

	unless (-f $file) {
		if (-d $file) {
			print "\n\t Cannot open file \"$file\" - it is a directory\n\n";
			return 0;
		}
		else {
			print "\n\t Cannot open file \"$file\"\n\n";
			return 0;
		}

 	}
	unless (open(INFILE, "$file")) {
		print "\n\t Cannot open file \"$file\"\n\n";
		return 0;
	}
	@$array_ref = <INFILE>;
	close INFILE;

	return 1;
}

#***************************************************************************
# Subroutine:  write_file
# Description: write an array to an ouput file
# Arguments:   $file: the name of the file to write to 
#              $array_ref: array to copy
#***************************************************************************
sub write_file {

	my ($file, $array_ref) = @_;
	unless (open(OUTFILE, ">$file")) {
		print "\n\t Couldn't open file \"$file\" for writing\n\n";
		return 0;
	}
	print OUTFILE @$array_ref;
	close OUTFILE;
	print "\n\t File \"$file\" created!\n\n";
}

#***************************************************************************
# Subroutine:  show_title
# Description: show command line title blurb 
#***************************************************************************
sub show_title {

	my $command = 'clear';
	system $command;
	my $title       = 'trackwrangler.pl';
	my $description = 'Genome track reformatting script';
	my $author      = 'Robert J. Gifford';
	my $contact	    = '<robert.gifford@glasgow.ac.uk>';
	show_about_box($title, $version_num, $description, $author, $contact);
}

#***************************************************************************
# Subroutine:  show_help_page
# Description: show help page information
#***************************************************************************
sub show_help_page {

	# Initialise usage statement to print if usage is incorrect
	my ($HELP)  = "\n\t Usage: $0 -m=[option] -i=[track file]\n";
        $HELP  .= "\n\t ### Mode options\n"; 
        $HELP  .= "\n\t -m=1  Convert REPBASE track"; 
        $HELP  .= "\n\t -m=2  Convert Retrotector track"; 
		$HELP  .= "\n\t -m=3  Convert DIGS track (supply name using -n)"; 
		$HELP  .= "\n\t -m=4  Convert Coffin track"; 
		$HELP  .= "\n\t -m=5  Convert to 'orientation provided' format"; 
		$HELP  .= "\n\n\n"; 
	print $HELP;
}

#***************************************************************************
# Subroutine:  show_about_box 
# Description: show a formatted title box for a console application
# Arguments:   the program description as a series of strings:
#              - $title, $version, $description, $author, $contact
#***************************************************************************
sub show_about_box {

	my ($title, $version, $description, $author, $contact) = @_;

	my $solid_line  = "\n\t" . '#' x $console_width;
	my $border_line = "\n\t" . '#' . (' ' x ($console_width - 2)) . "#";

	# Format the text
	my $title_version   = $title . ' ' . $version; 
	
	my $f_title_version = enclose_box_text($title_version);
	my $f_description   = enclose_box_text($description);
	my $f_author        = enclose_box_text($author);
	my $f_contact       = enclose_box_text($contact);

	# Print the box
	print "\n\n";
	print $solid_line;
	print $border_line;
	print $f_title_version;
	print $f_description;
	print $f_author;
	print $f_contact;
	print $border_line;
	print $solid_line;
	print "\n\n"; 
}

############################################################################
# Private Member Functions
############################################################################

#***************************************************************************
# Subroutine:  enclose_box_text
# Description: Format text for an about box by centering it within a box 
#***************************************************************************
sub enclose_box_text {

	my ($text) = @_;

	my $f_text;
	my $left_spacing;
	my $right_spacing;
	my $text_length = length $text;
	
	if ($text_length > ($console_width - 4)) {
		die ("\n\t Title field was more than max length");
	
	}
	else {
		# calculate total white space
		my $space = ($console_width - ($text_length + 2));
		
		# use this value to centre text
		$left_spacing = $space / 2;
		my $adjust_for_uneven = $space % 2;
		$right_spacing = ($space / 2) + $adjust_for_uneven;
	}

	$f_text  = "\n\t#" . (' ' x $left_spacing);
	$f_text .= $text;
	$f_text .= (' ' x $right_spacing) . "#";

	return $f_text;
}

############################################################################
# Deprecated
############################################################################


#***************************************************************************
# Subroutine:  create_loci_file_repbase_old
# Description: generate names using a track in the RepBase format
#***************************************************************************
sub create_loci_file_repbase_old {

	my ($infile) = @_;

	print "\n\t Applying the Missillac nomeclature to REPBASE-formatted track";
	sleep 1;

	my @output;
	
	# Read the file 
	my @raw_file;
	read_file($infile, \@raw_file);
	my $lines = scalar @raw_file;
	unless ($lines) {
		die "\n\t Unable to read infile '$infile'\n\n";
	}
	elsif ($lines eq 1) {
		print "\n\t Single line of data was read form infile '$infile'";
		die "\n\t Check line break formatting\n\n";
	}

	# Remove the header line
	my $header_line = shift @raw_file;

	# Process the file line by line
	my $erv_number = 0;
	foreach my $line (@raw_file) {

		chomp $line; # remove newline
		#print "\n\t LINE: $line"; exit;

		my @line = split("\t", $line); # Split on tabs
	
		# Get the data from the line 
		# (assumes the folowing column order)
		# Bin	swScore	milliDiv	milliIns	genoName	genoName	genoStart	genoEnd	genoLeft	strand	repName	repClass	repClass	repStart	repEnd	repLeft	ID
		my $bin       = $line[0];
		my $swScore   = $line[1];
		my $milliDiv  = $line[2];
		my $milliIns  = $line[3];
		my $genoName  = $line[4];
		my $genoName2 = $line[5];
		my $genoStart = $line[6];
		my $genoEnd   = $line[7];
		my $genoLeft  = $line[8];
		my $strand    = $line[9];
		my $repName   = $line[10];
		my $repClass  = $line[11];
		my $repClass = $line[12];
		my $repStart  = $line[13];
		my $repEnd    = $line[14];
		my $repLeft   = $line[15];
		my $id        = $line[16];
		
		# Create the locus name
		my $locus_name = normalize_names($repName, 'RepBase');
	
		if ($locus_name) {
			my $new_line = "RepBase\t$locus_name\t$genoName2\t$genoStart\t$genoEnd\t$repName\n";
			push (@output, $new_line);
		}
	}

	# Write the output
	my $outfile = $infile . '.missillac.txt';
	write_file($outfile, \@output)

}

#***************************************************************************
# Subroutine:  create_loci_file_coffin
# Description: generate names using a track in the RepBase format
#***************************************************************************
sub create_loci_file_coffin {

	my ($infile) = @_;

	print "\n\t Applying the Missillac nomeclature to COFFIN-formatted track";
	sleep 1;

	my @output;

	# Read the file 
	my @raw_file;
	read_file($infile, \@raw_file);
	my $lines = scalar @raw_file;
	unless ($lines) {
		die "\n\t Unable to read infile '$infile'\n\n";
	}
	elsif ($lines eq 1) {
		print "\n\t Only one  line of text was read from infile '$infile'";
		print "\n\t Check line break formatting\n\n"; exit;
	}

	# Remove the header line
	my $header_line = shift @raw_file;

	# Process the file line by line
	my $erv_number = 0;
	foreach my $line (@raw_file) {
	
		chomp $line; # remove newline
		#print "\n\t LINE: $line"; exit;

		my @line = split("\t", $line); # Split on tabs
		
		# Get the data from the line 
		# (note this assumes a certain column order)
		#	Order	Locus	ERV	Chr	Orientation	Start	End	OCA	Alias
		my $order         = $line[0];
		my $locus         = $line[1];
		my $erv_name      = $line[2];
		my $chr           = $line[3];
		my $orientation   = $line[4];
		my $extract_start = $line[5];
		my $extract_end   = $line[6];
		my $oca           = $line[7];
		my $alias         = $line[8];

		# Various ways to generate a unique id
		$erv_number++; # Increment counter by one
		my $id = $locus;

		my $start;
		my $end;
		if ($orientation eq '-') {
			$start = $extract_end;
			$end   = $extract_start;		
		}
		else {
			$start = $extract_start;		
			$end = $extract_end;
		}

		$chr = 'chr' . $chr;
		my $locus_name = 'ERV.K(HML2)';
		my $new_line = "Coffin\t$locus_name\t$chr\t$start\t$end\tProvirus\n";
		push (@output, $new_line);
				
	}

	# Write the output
	my $outfile = $infile . '.missillac.txt';
	write_file($outfile, \@output)
	
}

############################################################################
# EOF
############################################################################

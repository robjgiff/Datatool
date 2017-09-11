#!/usr/bin/perl -w
############################################################################
# Module:      DataToolCmd.pm
# Description: Command line interface to a data manipulation tool
# History:     November 2014: Created by Robert Gifford 
############################################################################
package DataToolCmd;

############################################################################
# Import statements/packages (externally developed packages)
############################################################################
use strict;

############################################################################
# Import statements/packages (internally developed packages)
############################################################################

# Base classes
use Base::BioIO;
use Base::FileIO;
use Base::SeqIO;
use Base::DevTools;
use Base::Console;
use Base::Sequence; 

############################################################################
# Globals
############################################################################

# Base class instantiations
my $fileio     = FileIO->new();
my $seqio      = SeqIO->new();
my $bioio      = BioIO->new();
my $devtools   = DevTools->new();
my $console    = Console->new();
my $output_dir = './output';
1;

############################################################################
# LIFECYCLE
############################################################################

#***************************************************************************
# Subroutine:  new
# Description: Parameters
#***************************************************************************
sub new {

	my ($invocant, $parameter_ref) = @_;
	my $class = ref($invocant) || $invocant;

	# Set member variables
	my $self = {
		
		# Member variables
		process_id           => $parameter_ref->{process_id},
		output_type          => $parameter_ref->{output_type},
		
		# Member classes
		datatool_obj         =>	$parameter_ref->{datatool_obj},
		
		# Paths
		output_path          => $parameter_ref->{output_path},
	};
	
	bless ($self, $class);
	return $self;
}


############################################################################
# TOP LEVEL HANDLERS
############################################################################

#***************************************************************************
# Subroutine:  run_reformat_tools_cmd_line
# Description: hand off to FASTA utilities
#***************************************************************************
sub run_reformat_tools_cmd_line {

	my ($self, $infile, $dir, $mode) = @_;

	$self->show_title();

	my $result;
	if    ($mode eq 1) {  # FASTA to delimited txt table 
		$result = $self->convert_fasta_to_delimited($infile);
	}
	elsif ($mode eq 2) { # Delimited to FASTA
		$result = $self->convert_delimited_to_fasta($infile);
	}
	elsif ($mode eq 3) {  # Genbank to FASTA + Data
		$self->convert_genbank_to_fasta_and_tabdelim($infile);
	}
	elsif ($mode eq 4) {  # NCBI to DIGS 
		$self->convert_ncbi_to_digs($infile);
	}
	elsif ($mode eq 5) {  # Write the REFSEQ sequence and its features to FASTA
		$self->refseq_to_fasta($dir, $infile);
	}
	elsif ($mode eq 6) {  # Write the REFSEQ sequence as Se-Al-friendly FASTA
		$self->refseq_to_seal_fasta($dir, $infile);
	}
	elsif ($mode eq 7) {  # Write the REFSEQ sequence as Se-Al-friendly FASTA
		$self->extract_features_from_refseq($dir);
	}
	elsif ($mode eq 8) {  # FASTA to NEXUS
		$self->convert_fasta_file_to_nexus($infile);
	}
	elsif ($mode eq 9) {  # FASTA TO PHYLIP
		$self->convert_fasta_file_to_phylip($infile);
	}
	elsif ($mode eq 10) {  # Write the REFSEQ sequence and its features to FASTA
		$self->write_GLUE_refseq_in_linear_format($infile);
	}
	else { die; }
	
	#	$self->convert_genbank_file_to_GLUE_refseq($infiles);
	#	$self->extract_genbank_cds_as_fasta($infiles);
	#	$self->create_mutation_list_from_glue_msa($infiles);	
	#elsif ($sort eq 6) {
		#$self->concatenate_aln_seqs_using_id($seqfiles, $datafiles);
	#}

	return $result;
}

#***************************************************************************
# Subroutine:  run_sort_tools_cmd_line
# Description: hand off to sorting utilities
#***************************************************************************
sub run_sort_tools_cmd_line {

	my ($self, $file1, $file2, $sort) = @_;
	
	my $process_id  = $self->{process_id};
	my $output_path = $self->{output_path};
	unless ($output_path) { $output_path .= './'; }		
	$self->show_title();

	if ($sort eq 1) {  # Shorten FASTA headers (capture data)
		$self->truncate_fasta_headers($file1);
	}
	elsif ($sort eq 2) {  # Sort by length
		$self->do_length_based_fasta_sort($file1, $file2);
	}
	elsif ($sort eq 2) {  # Filter based on phrase in FASTA header
		$self->do_header_based_fasta_filter($file1);
	}
	elsif ($sort eq 4) {
		print "\n\t # This function needs two files: -i=[file1] -c=[file2]\n\n";
		unless ($file1 and $file2) { exit; }
		$self->combine_data_from_two_files($file1, $file2);
	}
	elsif ($sort eq 5) {  # Do fasta sort using linked header file 
		$self->do_fasta_sort_using_delimited_file_column($file1, $file2);
	}
	elsif ($sort eq 6) {  #  Split FASTA
		$self->split_fasta($file1);
	}

	#$self->sort_aligned_seqs_by_start($seqfiles);	#}
	#$self->concatenate_fasta($infiles);
	else { die; }
}

#***************************************************************************
# Subroutine:  run_special_tools_cmd_line
# Description: hand off to sorting utilities
#***************************************************************************
sub run_special_tools_cmd_line {

	my ($self, $datafile, $special) = @_;
	
	my $process_id  = $self->{process_id};
	my $output_path = $self->{output_path};

	unless ($output_path) { $output_path .= './'; }	
	$self->show_title();
	
	if ($special eq 1) {  # Shorten FASTA headers (capture data)
		$self->do_rabv_cleanup($datafile);
	}
	else {
		die;
	}
}

############################################################################
# INTERNALS
############################################################################

#***************************************************************************
# Subroutine:  do_rabv_cleanup
# Description: 
#***************************************************************************
sub do_rabv_cleanup {

	my ($self, $datafile) = @_;

	my @rabv;
	$fileio->read_file($datafile, \@rabv);
	my $i = 0;
	my @clean;
	my $clean_line = '';
	foreach my $line (@rabv) {
	
		$i++;
		chomp $line;
		#print "\n\t ### LINE $i:  $line";

		my $is_odd  = $i % 2 == 1;
		if ($is_odd) {
			$clean_line = $self->clean_rabv_line($line);
		}
		else {
			$clean_line .= "\t$line\n";
			push (@clean, $clean_line);
			$clean_line = '';
		}
	}

	$fileio->write_file("$datafile.clean.txt", \@clean);


}

#***************************************************************************
# Subroutine:  clean_rabv_line
# Description: 
#***************************************************************************
sub clean_rabv_line {

	my ($self, $line) = @_;
	
	my @line = split("\t", $line);
	#$devtools->print_array(\@line); exit;
	my $reference = $line[7];
	my $clean_line;
	if ($reference =~ m/This study/) {
		
		my $accession = $line[6];
		my @accession = split('', $accession);
		pop @accession; # Lose last char
		my $new_accession = join('', @accession);
		my @clean_line;		
		my $i = 0;
		foreach my $item (@line) {		
			$i++;
			if ($i eq 7) { push (@clean_line, $new_accession);	}
			else         { push (@clean_line, $item);			}
		}
		$clean_line = join("\t", @clean_line);
	}
	else {
		$clean_line = $line;		
	}
	return $clean_line;
}

#***************************************************************************
# Subroutine:  extract_features_from_refseq
# Description: 
#***************************************************************************
sub extract_features_from_refseq {

	my ($self, $lib_path) = @_;

	my $parser_obj    = RefSeqParser->new();
	my @files1;
	my $outdir = 'outfiles/';
	$fileio->read_directory_to_array($lib_path, \@files1);	

	my @output;
	foreach my $file (@files1) {

		print "\n\t DOING $file";

		# Create reference sequence object
		my %params1;
		my $path1 = $lib_path . $file;
		$parser_obj->parse_refseq_flatfile($path1, \%params1);
		my $refseq1 = RefSeq->new(\%params1);
		#$refseq1->write_self_to_text($outdir);
		$file =~ s/\.txt//g;
		
		my $genes_ref    = $refseq1->{genes};
		my $features_ref = $refseq1->{features};
		#my @combined = push (@$genes_ref, @$features_ref);
		my @combined;
		push (@combined, @$genes_ref);
		if ($features_ref) {
			push (@combined, @$features_ref);
		}

		my %layers;
		foreach my $feature (@combined) {
			
			#$devtools->print_hash($feature); die;
			my $domain_type  = $feature->{type};
			my $name         = $feature->{name};
			my $start        = $feature->{start};
			my $stop         = $feature->{stop};
			print "\n\t\t $name ORF $start - $stop ($domain_type)";
			my $line = "$file\t$name\t$start\t$stop\n";
			push (@output, $line);
		}

	}
	$fileio->write_file('features.txt', \@output);
}

#***************************************************************************
# Subroutine:  refseq_to_fasta
# Description: write GLUE reference sequence as FASTA, with separate files
#              for ORFs (NT), translated ORFs (AA) and UTRs
#***************************************************************************
sub refseq_to_fasta {

	my ($self, $dir, $infile) = @_;

	my $seq_obj  = Sequence->new();    # Create a sequence object
	my $datatool = $self->{datatool_obj};
	my $parser   = RefSeqParser->new();
	
	my @files1;
	my $path_stem = '';
	if ($dir) {
		$path_stem = $dir;
		$fileio->read_directory_to_array($dir, \@files1);	
	}
	else {
		push(@files1, $infile);
	}

	my @outfile1; # All nt ORFs in library in one file
	my @outfile2; # All aa ORFs in library in one file
	my %outfile3;
	my %outfile4;
	foreach my $file (@files1) {

		print "\n\t DOING $file";

		my %params;
		my $path = $path_stem . $file;
		$parser->parse_refseq_flatfile($path, \%params);
		
		my $refseq = RefSeq->new(\%params);
		my $refseq_name = $refseq->{'name'};
		my %orfs;
		$refseq->get_orfs(\%orfs);
		my @outfile3; # nt ORFs for this reference
		my @outfile4; # aa ORFs for this reference
		my @orfs = sort keys %orfs;
		foreach my $orf (@orfs) {
			my $sequence = $orfs{$orf};
			my $fasta = ">$refseq_name $orf\n$sequence\n";
			push (@outfile1, $fasta);
			push (@outfile3, $fasta);
			my $aa_seq = $seq_obj->translate($sequence);
			my $digs_style_header = $refseq_name . '_' . $orf;
			my $aa_fasta = ">$digs_style_header\n$aa_seq\n";
			push (@outfile2, $aa_fasta);
			push (@outfile4, $aa_fasta);
		}
		$outfile3{$refseq_name} = \@outfile3;
		$outfile4{$refseq_name} = \@outfile4;
	}
	
	my $outfile1 = 'orfs.nt.fas';
	$fileio->write_file($outfile1, \@outfile1);
	print "\n\t file '$outfile1' created\n\n";
	my $outfile2 = 'orfs.aa.fas';
	$fileio->write_file($outfile2, \@outfile2);
	print "\n\t file '$outfile2' created\n\n";

	print "\n\t Writing file '$outfile2' created\n\n";
	my @names = keys %outfile4;
	foreach my $name (@names) {
		
		my $path = $output_dir . "/$name.faa";
		my $array_ref = $outfile4{$name};
		unless ($array_ref) { die; }
		$fileio->write_file($path, $array_ref);
	}
}

#***************************************************************************
# Subroutine:  refseq_to_seal_fasta
# Description: write GLUE reference sequence as FASTA, with separate files
#              for ORFs (NT), translated ORFs (AA) and UTRs
#***************************************************************************
sub refseq_to_seal_fasta {

	my ($self, $dir, $infile) = @_;

	my $datatool = $self->{datatool_obj};
	my $parser   = RefSeqParser->new();
	
	my @files1;
	my $path_stem = '';
	if ($dir) {
		$path_stem = $dir;
		$fileio->read_directory_to_array($dir, \@files1);	
	}
	else {
		push(@files1, $infile);
	}

	foreach my $file (@files1) {
	
		my $seq_obj = Sequence->new();    # Create a sequence object
		my $parser = RefSeqParser->new();
		my %params;
		my $path = $path_stem . $file;
		$parser->parse_refseq_flatfile($path, \%params);
		my $refseq = RefSeq->new(\%params);
		$refseq->write_self_to_seal();
	}
}

############################################################################
# MAIN FUNCTIONS
############################################################################

#***************************************************************************
# Subroutine:  convert_ncbi_to_digs
# Description: 
#***************************************************************************
sub convert_ncbi_to_digs {

	my ($self, $infile) = @_;

	my $datatool= $self->{datatool_obj};

	my $result = undef;
	my %hash;
	my %sequences;

	print "\n\t # Converting file '$infile' from NCBI fasta to DIGS fasta\n";
	my @fasta;
	$seqio->read_fasta($infile, \@fasta);
	my $num_seqs = scalar @fasta;
	unless ($num_seqs) { 
		print "\n\t # No sequences read from file '$infile'";
		next;
	}
	my @digs_fasta;
	$datatool->ncbi_to_digs(\@fasta, \@digs_fasta);
	my @infile = split('\.', $infile);
	pop @infile;
	$infile = join('', @infile);
	my $outfile = $infile . '.DIGS.fas';
	$fileio->write_file($outfile, \@digs_fasta);
	print "\n\t # File '$outfile' created";
	
}

#***************************************************************************
# Subroutine:  sort_aligned_seqs_by_start
# Description: 
#***************************************************************************
sub sort_aligned_seqs_by_start {

	my ($self, $infiles) = @_;

	my $datatool= $self->{datatool_obj};

	my $result = undef;
	my %hash;
	my %sequences;
	foreach my $infile (@$infiles) {

		print "\n\t # Converting file '$infile' from FASTA to data";
		my @fasta;
		$seqio->read_fasta($infile, \@fasta);
		my $num_seqs = scalar @fasta;
		unless ($num_seqs) { 
			print "\n\t # No sequences read from file '$infile'";
			next;
		}
		foreach my $seq_ref (@fasta) {
			my $seq_id   = $seq_ref->{sequence_id};
			my $sequence = $seq_ref->{sequence};
			my @sequence = split ('', $sequence);
			my $i = 0;
			foreach my $char (@sequence) {
				$i++;
				unless ($char eq '-') {
					last;
				}
			}
			$hash{$seq_id} = $i;
			$sequences{$seq_id} = $seq_ref;
		}

		my @sorted;
		print "\nSeqs IN ASCENDING NUMERIC ORDER:\n";
		foreach my $seq_id (sort { $hash{$a} <=> $hash{$b} } keys %hash) {
			print "\n\t # $seq_id, $hash{$seq_id}";
			my $seq_ref  = $sequences{$seq_id};
			my $header   = $seq_ref->{header};
			my $sequence = $seq_ref->{sequence};
			my $fasta = ">$header\n$sequence\n";
			push (@sorted, $fasta);
		}
		my $sorted_file = $infile . '.sorted.txt';
		print "\n\t Writing data to file '$sorted_file'";
		$fileio->write_file($sorted_file, \@sorted);

	}
}

#***************************************************************************
# Subroutine:  convert_fasta_to_delimited
# Description: convert FASTA formatted filed to tab-deimited columns 
#              column 1 (ID), column 2 (sequence)
#***************************************************************************
sub convert_fasta_to_delimited {

	my ($self, $infile) = @_;

	my $datatool= $self->{datatool_obj};

	my $result = undef;
	print "\n\t # Converting file '$infile' from FASTA to data";
	my @fasta;
	$seqio->read_fasta($infile, \@fasta);
	my $num_seqs = scalar @fasta;
	unless ($num_seqs) { 
		print "\n\t # No sequences read from file '$infile'";
		next;
	}
	my $delimiter;
	my $question = "\n\t What is the delimiter (comma\/tab)";
	my @choices  = qw [ c t ];
	my $choice = $console->ask_simple_choice_question($question, \@choices);
	if ($choice eq 'c') { $delimiter = ',';  }
	if ($choice eq 't') { $delimiter = "\t"; }
	my @data;
	$datatool->fasta_to_delimited(\@fasta, \@data, $delimiter);
		
	my @infile = split('\.', $infile);
	pop @infile;
	$infile = join('', @infile);
	my $outfile = $infile . '.txt';
	$result = $fileio->write_file($outfile, \@data);
	print "\n\t # File '$outfile' created";
	
	return $result;
}

#***************************************************************************
# Subroutine:  convert_delimited_to_fasta
# Description: convert tab-delimited columns (seq in last column) to FASTA
#***************************************************************************
sub convert_delimited_to_fasta {

	my ($self, $infile) = @_;

	my $datatool= $self->{datatool_obj};
	my @data;
	$fileio->read_file($infile, \@data);
	my @fasta;
	my $delimiter;
	my $question = "\n\t What is the delimiter (comma\/tab)";
	my @choices  = qw [ c t ];
	my $choice = $console->ask_simple_choice_question($question, \@choices);
	if ($choice eq 'c') { $delimiter = ',';  }
	if ($choice eq 't') { $delimiter = "\t"; }
	my @infile = split('\.', $infile);
	pop @infile;
	$infile = join('', @infile);
	my $outfile = "$infile.fas";
	$datatool->delimited_to_fasta(\@data, \@fasta, $delimiter);
	$fileio->write_file($outfile, \@fasta);
	print "\n\t # File '$outfile' created";
	#$devtools->print_array(\@data); die;

}

#***************************************************************************
# Subroutine:  convert_genbank_to_fasta_and_tabdelim
# Description: convert genbank to (i) fasta and (ii) data in a tab-delimited file
# Notes:       can deal with multiple, concatenated Genbank files
#***************************************************************************
sub convert_genbank_to_fasta_and_tabdelim {

	my ($self, $infiles) = @_;

	my $datatool= $self->{datatool_obj};

	foreach my $infile (@$infiles) {
	
		print "\n\t # Converting file '$infile' from GenBank format to FASTA+DATA";
		my @fasta;
		my %data;
		$datatool->genbank_to_fasta_and_data2($infile, \@fasta, \%data);
		#$devtools->print_array(\@fasta); #$devtools->print_hash(\%data); # DEBUG

		# Declare data structures for filtering
		my @fasta_in;
		my @fasta_out;
		my %options;

		# Ask which direction (above or below threshold)
		my @choices = qw [ above below ];
		my $question = "\n\t Exclude sequence above or below threshold";
		my $direction = $console->ask_simple_choice_question($question, \@choices);

		# Get threshold
		my $question1 = "\n\t Specify sequence length threshold";
		my $threshold = $console->ask_int_question($question1);

		# Record options	
		$options{threshold}  = $threshold;
		$options{direction}  = $direction;
		$options{count_gaps} = 1;
		$datatool->filter_seqs_by_length(\@fasta, \@fasta_in, \@fasta_out, \%options);

		# Write the fasta for the included sequences
		my $inseqs = $infile . '.included.fas';
		print "\n\t Writing sequences to file '$inseqs'";
		$seqio->write_fasta($inseqs, \@fasta_in);
		print "\n\t # File '$inseqs' created";

		# Write the data for the included sequences
		my @in_data;
		foreach my $seq_ref (@fasta_in) {
			my $seq_id   = $seq_ref->{sequence_id};
			my $data_ref = $data{$seq_id};
			push (@in_data, $data_ref);
		}
		my $indata = $infile . '.included.txt';
		print "\n\t Writing data to file '$indata'";
		#$seqio->write_delimited($indata, \@in_data, 'exclude_seq');
		$seqio->write_delimited($indata, \@in_data);

		# Write the fasta for the excluded sequences
		my $outseqs = $infile . '.excluded.fas';
		print "\n\t Writing sequences to file '$outseqs'";
		$seqio->write_fasta($outseqs, \@fasta_out);
		my @out_data;
		foreach my $seq_ref (@fasta_out) {
			my $seq_id   = $seq_ref->{sequence_id};
			my $data_ref = $data{$seq_id};
			push (@out_data, $data_ref);
		}
		my $outdata = $infile . '.excluded.txt';
		print "\n\t Writing data to file '$outdata'";
		$seqio->write_delimited($outdata, \@out_data);

	}
}

#***************************************************************************
# Subroutine:  extract_genbank_cds_as_fasta
# Description: convert genbank file to a GLUE refseq with features table
#***************************************************************************
sub extract_genbank_cds_as_fasta {

	my ($self, $infiles) = @_;

	foreach my $file (@$infiles) {

		print "\n\t File $file";
		my @file;
		$fileio->read_file($file, \@file);
		foreach my $line (@file) {


		}
	}

	my $directory = './bugr/';
	die;
	foreach my $file (@$infiles) {

		print "\n\t File $file";
		my @file;
		$fileio->read_file($file, \@file);
		#$devtools->print_array(\@file);
		my $join = join("", @file);
		my @split = split("\/\/", $join);
		my $i;
		foreach my $gb_entry (@split) {
			$i++;
			$gb_entry .= "\n//";
			#print $gb_entry; die;
			my $single_file = $directory . "/$i" . '.tmp';
			$fileio->write_text_to_file($single_file, $gb_entry);
			my @refseq;
			my $seq = $bioio->parse_gb_to_refseq($single_file, \@refseq);
			unless ($seq) {
				my @single_file = split("\n", $single_file);
				my $des = shift @single_file;
				print "\n\t No seq for $des";
				next;
			}

			my $refseq_path = $single_file . '.glu';
			$fileio->write_file($refseq_path, \@refseq);
			#print "\n\t # File $refseq_path created\n\n";
		
			my $seq_obj = Sequence->new();    # Create a sequence object
			my $parser = RefSeqParser->new();
			my %params;
			$parser->parse_refseq_flatfile($refseq_path, \%params);
			my $refseq = RefSeq->new(\%params);
			my $refseq_name = $refseq->{'name'};
			print "\n\t # Writing ORFs for $refseq_name\n\n";
			my %orfs;
			$refseq->get_orfs(\%orfs);
			my @orfs = sort keys %orfs;
			my @outfile1;
			my @outfile2;
			my $got_orfs = undef;
			foreach my $orf (@orfs) {
				my $sequence = $orfs{$orf};
				my $fasta = ">$refseq_name $orf\n$sequence\n";
				push (@outfile1, $fasta);
				my $aa_seq = $seq_obj->translate($sequence);
				my $aa_fasta = ">$refseq_name $orf\n$aa_seq\n";
				push (@outfile2, $aa_fasta);
				$got_orfs = 'true';
			}
			unless ($got_orfs) { next; }
			my $outfile1 = $directory . $refseq_name . '.orfs.nt.fas';
			$fileio->write_file($outfile1, \@outfile1);
			my $outfile2 = $directory . $refseq_name . '.orfs.aa.fas';
			$fileio->write_file($outfile2, \@outfile2);
			#print "\n\t file '$outfile' created\n\n";

			my $newname = "$directory/$refseq_name.glu";
			my $clean1  = "mv $refseq_path $newname";
			my $clean2  = "rm $single_file";
			#system $clean1;
			#system $clean2;

		}
	}
}

#***************************************************************************
# Subroutine:  convert_genbank_file_to_GLUE_refseq
# Description: convert genbank file to a GLUE refseq with features table
#***************************************************************************
sub convert_genbank_file_to_GLUE_refseq {

	my ($self, $infiles) = @_;

	my $datatool= $self->{datatool_obj};

	foreach my $infile (@$infiles) {
		print "\n\t # Converting file '$infile' from GenBank format to GLUE format";
		my @genbank;
		my @refseq;
		$bioio->parse_gb_to_refseq($infile, \@refseq);
		my $refseq_path = $infile . '.glu';
		$fileio->write_file($refseq_path, \@refseq);
		print "\n\t # File $refseq_path created\n\n";
	}
}

#***************************************************************************
# Subroutine:  write_GLUE_refseq_in_linear_format
# Description: write GLUE reference sequence in linear format with both
#              nucleotide sequence and ORF features displayed 
#***************************************************************************
sub write_GLUE_refseq_in_linear_format {

	my ($self, $infile, $dir) = @_;

	my $datatool= $self->{datatool_obj};

	print "\n\t # Writing GLUE reference sequence '$infile' in linear format ";
	my $parser = RefSeqParser->new();
	my %params;
	$parser->parse_refseq_flatfile($infile, \%params);
	my $refseq = RefSeq->new(\%params);
	my %linear;
	$refseq->create_linear_formatted(\%linear);
	my $outfile = $infile . '.formatted.txt';
	$refseq->write_linear_formatted_seq(\%linear, $outfile);
	print "\n\t file '$outfile' created\n\n";

}

#***************************************************************************
# Subroutine:  convert_fasta_file_to_nexus
# Description: command line interface for a FASTA-to-NEXUS conversion
#***************************************************************************
sub convert_fasta_file_to_nexus {

	my ($self, $infile) = @_;

	my $datatool= $self->{datatool_obj};

	print "\n\t # Converting file '$infile' from FASTA to NEXUS format";
	my @fasta;
	$seqio->read_fasta($infile, \@fasta);
	my $num_taxa = scalar @fasta;
	unless ($num_taxa) { die "\n\t NO SEQUENCES in '$infile'\n\n\n"; }
	my @nexus;
	$self->fasta_to_nexus(\@fasta, \@nexus);
	my $outfile = $infile . '.nex';
	$fileio->write_file($outfile, \@nexus);
	print "\n\t # File '$outfile' created";
}

#***************************************************************************
# Subroutine:  convert_fasta_file_to_phylip 
# Description: command line interface for a FASTA-to-PHYLIP conversion
#***************************************************************************
sub convert_fasta_file_to_phylip {

	my ($self, $infile) = @_;

	my $datatool= $self->{datatool_obj};
	print "\n\t # Converting file '$infile' from FASTA to PHYLIP format";
	my @fasta;
	$seqio->read_fasta($infile, \@fasta);
	my $num_taxa = scalar @fasta;
	unless ($num_taxa) { die "\n\t NO SEQUENCES in '$infile'\n\n\n"; }
	my @phylip;
	$self->fasta_to_phylip(\@fasta, \@phylip);
	my $outfile = $infile . '.phy';
	$fileio->write_file($outfile, \@phylip);
	print "\n\t # File '$outfile' created";
}

#***************************************************************************
# Subroutine:  concatenate_fasta
# Description: concatenate FASTA files
#***************************************************************************
sub concatenate_fasta {

	my ($self, $infiles) = @_;

	my $datatool= $self->{datatool_obj};

	my %lengths;
	my %concatenated;
	my %seq_ids;
	foreach my $infile (@$infiles) {

		print "\n\t infile '$infile'";
		my $seq_len;
		my %fileseqs;
		
		# Sequences
		my @sequences;
		$seqio->read_fasta($infile, \@sequences);
		foreach my $seq_ref (@sequences) {
			my $seq_id   = $seq_ref->{header};
			my $sequence = $seq_ref->{sequence};
			$seq_ids{$seq_id} = 1;
			$seq_len  = length $sequence;			
			if ($fileseqs{$seq_id}) {
				die;
			}
			else {
				$fileseqs{$seq_id} = $sequence;
			}
		}
		$concatenated{$infile} = \%fileseqs;
		$lengths{$infile}      = $seq_len;
	}
	#$devtools->print_hash(\%concatenated); die;

	
	my @segments;
	my @concatenated;
	my @seqids = keys %seq_ids;
	foreach my $seq_id (@seqids){

		my $segments = "";
		my $concatenated_seq = "";
		foreach my $infile (@$infiles) {
			
			my $concatenation_ref = $concatenated{$infile};
			my $sequence = $concatenation_ref->{$seq_id};
			unless ($sequence) {
				print "\n\t No sequence for '$seq_id' in file '$infile";
				my $seq_len = $lengths{$infile};
				my $pad = '-' x $seq_len;
				$concatenated_seq .= $pad;	
				$segments .= '-';	
			}
			else {
				$concatenated_seq .= $sequence;	
				$segments .= 'X';	
			}
		}
		my $fasta = ">$seq_id\n$concatenated_seq\n\n";
		push (@concatenated, $fasta);
		my $line = "$seq_id\t$segments\n";
		push (@segments, $line);
	}
	
	# Write files	
	$fileio->write_file('concatenated.fas', \@concatenated);
	$fileio->write_file('segment_matching.txt', \@segments);

}

#***************************************************************************
# Subroutine:  split_multisequence_glue_file
# Description: FASTA to delimited 
#***************************************************************************
sub split_multisequence_glue_file {

	my ($self, $file) = @_;

	print "\n\t # Splitting refseq file '$file'";
	my @refseqs;
	my $parser_obj = RefSeqParser->new();
	$parser_obj->split_glue_refseq_file($file, \@refseqs);

	foreach my $refseq_ref (@refseqs) {
		
		# Extract and parse the features block
		my %refseq_data;
		$parser_obj->parse_refseq_metadata($refseq_ref, \%refseq_data);
		my $name = $refseq_data{name};
		unless ($name) { die "No name found for refseq"; }
		#$devtools->print_hash(\%refseq_data); die;
		
		# Write the file
		$fileio->write_output_file($name, $refseq_ref);
	}
}

#***************************************************************************
# Subroutine:  create_mutation_list_from_glue_msa
# Description: cmd line interface to derive a mutation list from a GLUE MSA
#***************************************************************************
sub create_mutation_list_from_glue_msa {

	my ($self, $file) = @_;

	# Get the settings for the list
	my %list;	
	my $question2 = "\n\t Record mutations above or below threshold?";
	my @choices = qw [ above below ];
	my $rule  = $console->ask_simple_choice_question($question2, \@choices);
	my $question1 = "\n\t Specify threshold proportion as a percentage";
	my $threshold = $console->ask_int_with_bounds_question($question1, 0, 100);
	
	# Create the list
	my $alignment = RefSeqAlignment->new();
	$alignment->derive_typical_list($file, \%list, $threshold);
	$alignment->write_typical_list('typical_list.txt', \%list);
}

#***************************************************************************
# Subroutine:  truncate_fasta_headers
# Description: write GLUE reference sequence in linear format with both
#***************************************************************************
sub truncate_fasta_headers {

	my ($self, $seqfile) = @_;

	my @sequences;
	$seqio->read_fasta($seqfile, \@sequences);
	my @truncated;
	foreach my $seq_ref (@sequences) {
		$seq_ref->truncate_header();
		my $header = $seq_ref->{header};
		my $sequence = $seq_ref->{sequence};
		my  $fasta = ">$header\n$sequence\n";
		push (@truncated, $fasta);
	}
	my $outfile = $seqfile .= '.truncated.fas';
	$fileio->write_file($outfile, \@truncated);
	print "\n\t ### File '$outfile' created";
}

#***************************************************************************
# Subroutine:  do_length_based_fasta_sort
# Description: command line interface for a lenth based FASTA sort 
#***************************************************************************
sub do_length_based_fasta_sort {

	my ($self, $seqfile, $datafile) = @_;

	my $datatool = $self->{datatool_obj};
	my @fasta;
	$seqio->read_fasta($seqfile, \@fasta);
	
	my $question2 = "\n\t Count gaps?";
	my $count_gaps = $console->ask_yes_no_question($question2);
	if ($count_gaps eq 'n') { $count_gaps = undef; }

	my $high;
	my $count = 0;
	foreach my $seq_ref (@fasta) {
		$count++;
		my $sequence   = $seq_ref->{sequence};
		if ($count_gaps) {
			$sequence =~ s/-//g;
			$sequence =~ s/~//g;
			$sequence =~ s/\.//g;
		}
		my $seq_length = length $sequence;
		unless ($high) { $high = $seq_length; }
		if ($seq_length > $high) { $high = $seq_length; } 
	}
	unless ($high) { die; }
	
	my @sorted;
	my $excluded = 0;
	$excluded = $datatool->sort_seqs_by_length(\@fasta, \@sorted, $count_gaps);

	my $outfile = $seqfile .= '.sorted.fas';
	$fileio->write_file($outfile, \@sorted);

	print "\n\t ### File '$outfile' created";
	print "\n\t ### There were a total of $count sequences";
}

#***************************************************************************
# Subroutine:  do_header_based_fasta_filter
# Description: command line interface for a FASTA header-based filter fxn
#***************************************************************************
sub do_header_based_fasta_filter {

	my ($self, $infile) = @_;

	my $sequences_ref = $self->{sequences};
	my $question1 = "\n\t Enter phrase to filter on:";
	my $word  = $console->ask_question($question1);
	my $question2 = "\n\t Exclude or include?";
	my @choices = qw [ exclude include ];
	my $rule  = $console->ask_simple_choice_question($question2, \@choices);
	my $question3 = "\n\t Ignore case?";
	my $case  = $console->ask_yes_no_question($question3);
	my @filtered;
	my $filtered = 0;
	$filtered = $self->filter_by_header($sequences_ref, \@filtered, $word, $rule, $case);
	print "\n\t filtered $filtered sequences with headers containing phrase '$word'";
	# convert to sequence objects
	my @filtered_seqs; 	
	$seqio->convert_fasta(\@filtered, \@filtered_seqs);
	$self->{sequences} = \@filtered_seqs;
}

#***************************************************************************
# Subroutine:  combine_data_from_two_files 
# Description: 
#***************************************************************************
sub combine_data_from_two_files {

	my ($self, $seqfile, $datafile) = @_;

	my $datatool = $self->{datatool_obj};

	print "\n\t # file1 '$seqfile' file2 '$datafile'";

	my @data1;
	$fileio->read_file($seqfile, \@data1);
	my @data2;
	$fileio->read_file($datafile, \@data2);

 	#my $delimiter;
	#my $question = "\n\t What is the delimiter (comma\/tab)";
	#my @choices  = qw [ c t ];
	#my $choice = $console->ask_simple_choice_question($question, \@choices);
	#if ($choice eq 'c') { $delimiter = ',';  }
	#if ($choice eq 't') { $delimiter = "\t"; }
	
	# get the indices
	my $file1_question = "\n\t Which column contains the sequence IDs in file 1?";
	my $a_index = $console->ask_int_question($file1_question);
	$a_index--;
	my $file2_question = "\n\t Which column contains the sequence IDs in file 2?";
	my $b_index = $console->ask_int_question($file2_question);
	$b_index--;
	$datatool->combine_data(\@data1, \@data2, $a_index, $b_index);
}


#***************************************************************************
# Subroutine:  do_fasta_sort_using_delimited_file_column 
# Description: sort a FASTA file using a column of values in a delimited file
#***************************************************************************
sub do_fasta_sort_using_delimited_file_column {

	my ($self, $seqfile, $datafile) = @_;

	my @fasta;
	$seqio->read_fasta($seqfile, \@fasta);
	my @data;
	$fileio->read_file($datafile, \@data);
	my $delimiter;
	my $question = "\n\t What is the delimiter (comma\/tab)";
	my @choices  = qw [ c t ];
	my $choice = $console->ask_simple_choice_question($question, \@choices);
	if ($choice eq 'c') { $delimiter = ',';  }
	if ($choice eq 't') { $delimiter = "\t"; }

	# get the indices
	$question = "\n\t Which column contains the sequence IDs?";
	my $id_index = $console->ask_int_question($question);
	$id_index--;
	$question = "\n\t Which column contains the data to sort on?";
	my $sub_index = $console->ask_int_question($question);
	$sub_index--;
	die "\n\t UNFINISHdED, SORRY\n\n"; #TODO
	$self->sort_sequences_on_data_column(\@fasta, \@data, $id_index, $sub_index, $delimiter);
}

#***************************************************************************
# Subroutine:  concatenate_aln_seqs_using_id 
# Description: 
#***************************************************************************
sub concatenate_aln_seqs_using_id {

	my ($self, $seqfiles, $datafiles) = @_;

	shift @$datafiles;
	my $seqfile  = shift @$seqfiles;
	my $datafile = shift @$datafiles;
	print "\n\t # file1 '$seqfile' file2 '$datafile'";

	my @seqs;
	$seqio->read_fasta($seqfile, \@seqs);
	my @data;
	$fileio->read_file($datafile, \@data);

 	my $delimiter;
	my $question = "\n\t What is the delimiter (comma\/tab)";
	my @choices  = qw [ c t ];
	my $choice = $console->ask_simple_choice_question($question, \@choices);
	if ($choice eq 'c') { $delimiter = ',';  }
	if ($choice eq 't') { $delimiter = "\t"; }
	
	# get the indices
	$question = "\n\t Which column contains the ID for concatenation?";
	my $index = $console->ask_int_question($question);
	$index--;

	# get the ID FOR SEQUENCES
	$question = "\n\t Which column contains the unique sequence ID?";
	my $id_index = $console->ask_int_question($question);
	$id_index--;

	# Get the data indexed by unique id
	#my $fields = shift @data;
	my %data_by_unique_id;
	foreach my $line (@data) {
		chomp $line;
		my @line = split($delimiter, $line);
		my $unique_id = $line[$id_index];
 		$data_by_unique_id{$unique_id} = $line;
	}
	#$devtools->print_hash(\%seqs_by_unique_id); exit;


	# Get the sequences indexed by unique id
	my %seqs_by_unique_id;
	foreach my $seq (@seqs) {
		#$devtools->print_hash($seq);
		my $unique_id = $seq->{header};
		my $sequence  = $seq->{sequence};
		$seqs_by_unique_id{$unique_id} = $seq;
	}
	#$devtools->print_hash(\%seqs_by_unique_id); exit;

	# Iterate through data
	my %join;
	foreach my $line (@data) {

		chomp $line;
		my @line = split ($delimiter, $line);	
		my $value     = $line[$index];
		my $unique_id = $line[$id_index];
		my $seq = $seqs_by_unique_id{$unique_id};
		unless ($seq) { 
			print "\n\t No sequence found for ID '$unique_id'";
			next; 
		}

		print "\n\t ## Strain ID: $unique_id: '$value'";
		if ($join{$value}) {
			my $array_ref = $join{$value};
			push (@$array_ref, $seq);
		}
		else {
			my @array;
			push (@array, $seq);
			$join{$value} = \@array;
		}
	}

	# Merge sequences
	my @merged;
	my @merged_data;
	my @keys = keys %join;
	foreach my $key (@keys) {

		my $seq_array = $join{$key};
		my $data = $self->merge_sequences($seq_array, \%data_by_unique_id,  \@merged, $delimiter);
		push (@merged_data, "$data\n");

	}

	my $file_out = $seqfile . '.merge.txt';
	print "\n\t Writing file '$file_out'";
	$fileio->write_file($file_out, \@merged);

	my $file_out2 = $seqfile . '.merge_data.txt';
	print "\n\t Writing file '$file_out2'";
	$fileio->write_file($file_out2, \@merged_data);
}

#***************************************************************************
# Subroutine:  merge_sequences
# Description: does what it says 
#***************************************************************************
sub merge_sequences {

	my ($self, $input_array, $data_hash, $output_array, $delimiter) = @_;

	my %merged;
	my @data;
	my @ids;
	foreach my $seq_ref (@$input_array) {

		my $sequence_id = $seq_ref->{header};
		my $sequence    = $seq_ref->{sequence};
		push (@ids, $sequence_id);

		my $data = $data_hash->{$sequence_id};
		unless ($data)  { die "\n\t No data for sequence '$sequence_id'\n\n"; }
		push (@data, $data);

		my $i = 0;
		my @sequence = split('', $sequence);
		foreach my $char (@sequence) {
			$i++;
			if ($merged{$i}) {
				my $other_char = $merged{$i};
				if ($other_char eq '-') {
					$merged{$i} = $char;
				}
				else {
					unless ($char eq '-') {
						unless ($char eq $other_char) {
							print "\n\t Warning - nucleotide clash: for $sequence_id: '$char' differs from '$other_char'";
						}	
					}
				}
			}
			else {
				$merged{$i} = $char;
			}
		}
	}

	# Merge the data
	my %merged_data;
	foreach my $line (@data) {
		chomp $line;
		my @line = split($delimiter, $line);
		my $i = 0;
		foreach my $value (@line) {
			$i++;
			if ($merged_data{$i}) {
				my $hash_ref = $merged_data{$i};
				$hash_ref->{$value} = 1;
			}
			else {
				my %hash;
				$hash{$value} = 1;
				$merged_data{$i} = \%hash;
			}
		}
	}
	#$devtools->print_array(\@data);
	#$devtools->print_hash(\%merged_data);
	
	my @merged_data;
	my @keys = sort by_number keys %merged_data;
	foreach my $key (@keys) {
		my $hash_ref = $merged_data{$key};
		my @values = keys %$hash_ref;
		my $value = join('|', @values);
		push (@merged_data, $value);
	}
	#print "\n\t ### here";
	#$devtools->print_array(\@merged_data);
	my $merge_id = join($delimiter, @merged_data);
	print "\n\t ID: $merge_id";

	my @nucs = sort by_number keys %merged;
	my $merged;
	foreach my $position (@nucs) {
		my $char = $merged{$position}; 
		$merged .= $char;
	}
	my $fasta = ">$merge_id\n$merged\n";
	
	push (@$output_array, $fasta);
	return $merge_id;
}


#***************************************************************************
# Subroutine:  split_fasta
# Description: split multi sequence file into individual FASTA files
#***************************************************************************
sub split_fasta {

	my ($self, $infile) = @_;
	
	# get the file name and read
	my @fasta;
	$seqio->read_fasta($infile, \@fasta);

	my @infile = split('\.', $infile);
	my $file_stem = shift @infile;
	$file_stem =~ s/ /_/g;
	my $directory = $file_stem . '_files';
	$fileio->create_directory($directory);
		
	my $i;
	my @sequence;
	foreach my $seq_obj (@fasta) {
	
		$i++;
		my $header   = $seq_obj->{header};
		my $sequence = $seq_obj->{sequence};
		$header =~ s/ /_/g;
		my $fasta = ">$header\n$sequence\n\n";
		my $file_path = "$directory/$header" . ".fna";
		#print "\n\t Read $i: $header";
		$fileio->write_text_to_file($file_path, $fasta);

	}
}

############################################################################
# Command line title blurb 
############################################################################

#***************************************************************************
# Subroutine:  show_title
# Description: does what it says 
#***************************************************************************
sub show_title {

	$console->refresh();
	my $title       = 'GLUE Data tool';
	my $version     = '2.0';
	my $description = 'GLUE-associated data tool';
	my $author      = 'Robert J. Gifford';
	my $contact		= '<robert.gifford@glasgow.ac.uk>';
	$console->show_about_box($title, $version, $description, $author, $contact);
}

#***************************************************************************
# Subroutine:  show_help_page
# Description: show help page information
#***************************************************************************
sub show_help_page {

	my ($HELP) = "\n\t usage: $0 -m[options] -s[options] -i[infile]";

	$HELP    .= " -c[comparison file] -d[directory]";
	$HELP    .= "\n\n\t # Convert between formats";

	$HELP  .= "\n\t  -m=1   :   FASTA to Delimited";
	$HELP  .= "\n\t  -m=2   :   Delimited to FASTA";
	$HELP  .= "\n\t  -m=3   :   Genbank to FASTA+DATA";
	$HELP  .= "\n\t  -m=4   :   NCBI refseq FASTA to DIGS input";
	$HELP  .= "\n\t  -m=5   :   REFSEQ to FASTA";
	$HELP  .= "\n\t  -m=6   :   REFSEQ to Se-Al-friendly FASTA";
	$HELP  .= "\n\t  -m=7   :   REFSEQ features to GLUE (java version) feature table";
	$HELP  .= "\n\t  -m=8   :   FASTA to NEXUS";
	$HELP  .= "\n\t  -m=9   :   FASTA to PHYLIP";
	$HELP  .= "\n\t  -m=10  :   REFSEQ to linear formatted"; 

	$HELP  .= "\n\n\t # Sorting, filtering, linking";
	$HELP  .= "\n\t  -s=1   :   Shorten FASTA headers"; 
	$HELP  .= "\n\t  -s=2   :   Sort sequences by length"; 
	$HELP  .= "\n\t  -s=3   :   Filter sequences by keyword"; 
	$HELP  .= "\n\t  -s=4   :   Link two data files using a shared ID";
	$HELP  .= "\n\t  -s=5   :   Sort sequences by data column"; 
	$HELP  .= "\n\t  -s=6   :   Split multi-sequence FASTA into individual files "; 
	#$HELP  .= "\n\t  -s=7   :   Concatenate using shared ID"; 
	#$HELP  .= "\n\t  -s=8   :   Order aligned seqs by start position (staggered)"; 
	#$HELP  .= "\n\t  -m=9   :   Concatenate FASTA files";
	
	print $HELP;
}

#***************************************************************************
# Subroutine:  by number
# Description: by number - for use with perl 'sort'  (cryptic but works) 
#***************************************************************************
sub by_number { $a <=> $b }	

############################################################################
# EOF
############################################################################

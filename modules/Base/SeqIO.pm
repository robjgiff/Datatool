############################################################################
# Module:       SeqIO.pm 
# Description:  Provides fxns for reading and writing biological 
#               sequence data 
# History:      Rob Gifford, May 2009: Creation
############################################################################
package SeqIO;

############################################################################
# Import statements/packages (externally developed packages)
############################################################################
use strict;

############################################################################
# Import statements/packages (internally developed packages)
############################################################################

# Base classes
use Base::FileIO;
use Base::DevTools;
use Base::Sequence;

############################################################################
# Globals
############################################################################
	
my $coverage_minimum = 0.65;

my $fileio   = FileIO->new();
my $devtools = DevTools->new();
1;

############################################################################
# LIFECYCLE
############################################################################

#***************************************************************************
# Subroutine:  new
# Description: Parameters
#***************************************************************************
sub new {

	my ($invocant) = @_;
	my $class = ref($invocant) || $invocant;

	# Member variables
	my $self = {
	
	};
	
	bless ($self, $class);
	return $self;
}

############################################################################
# Reading Fxns 
############################################################################

#***************************************************************************
# Subroutine:  read_fasta
# Description: read a fasta file into an array of hashes. 
# Arguments:   $file: the name of the file to read
#              $array_ref: reference to the hash array to copy to
#***************************************************************************
sub read_fasta {

	my ($self, $file, $array_ref, $identifier) = @_;
	
	unless ($identifier) { $identifier = 'SEQ_'; }

	# Read in the file or else return
	unless (open(INFILE, $file)) {
		print "\n\t Cannot open file \"$file\"\n\n";
		return undef;
	}

	# Use process ID and time to create unique ID stem
	my $pid  = $$;
	my $time = time;
	my $alias_stem = $identifier;
	
	# Iterate through lines in the file
	my @raw_fasta = <INFILE>;
	close INFILE;
	my $header;
    my $sequence;
   	my $i = 0;
	foreach my $line (@raw_fasta) {
		
		#print "\n## $i";
		chomp $line;
		if    ($line =~ /^\s*$/)   { next; } # discard blank line
		elsif ($line =~ /^\s*#/)   { next; } # discard comment line 
		elsif ($line =~ /^BEGIN/)  { last; } # stop if we reach a data block
		elsif ($line =~ /^>/) {
			
			$line =~ s/^>//g;
					
			# new header, store any sequence held in the buffer
			if ($header and $sequence) {
				$i++;
				my $alias_id = $alias_stem . "_$i";
				$sequence = uc $sequence;
				#$header = $self->clean_fasta_header($header);
				my $seq_obj = Sequence->new($sequence, $header, $alias_id);
				#$devtools->print_hash($seq_obj); die;
				push(@$array_ref, $seq_obj);
			}
		
			# reset the variables 
			$line =~ s/^>//;
			$header = $line;
			$sequence = undef;
		}
		else {
			# keep line, add to sequence string
            $sequence .= $line;
     	}
    }
	
	# Before exit, store any sequence held in the buffer
	if ($header and $sequence) {
		$i++;
		my $alias_id = $alias_stem . "_$i";
		$sequence =~ s/\s+//g; # Remove whitespace
		$sequence = uc $sequence;
		$header = $self->clean_fasta_header($header);
		my $seq_obj = Sequence->new($sequence, $header, $alias_id);
		push(@$array_ref, $seq_obj);
	}
}

#***************************************************************************
# Subroutine:  clean_fasta_header
# Description: 
#***************************************************************************
sub clean_fasta_header {

	my ($self, $header) = @_;
	
	$header =~ s/\s+/_/g;
	$header =~ s/\|//g;
	$header =~ s/\.//g;
	$header =~ s/\(/-/g;
	$header =~ s/\)/-/g;
	$header =~ s/://g;
	$header =~ s/,//g;

	return $header
}

#***************************************************************************
# Subroutine:  read_GLUE_MSA
# Description: 
#***************************************************************************
sub read_GLUE_MSA {

	my ($self, $file, $hash_ref, $extract_start, $extract_stop) = @_;
	
	# Read in the file or else return
	unless (open(INFILE, $file)) {
		print "\n\t Cannot open file \"$file\"\n\n";
		return undef;
	}

	# Use process ID and time to create unique ID stem
	my $pid  = $$;
	my $time = time;
	#my $alias_stem = $pid . '_' . $time . '_';
	my $alias_stem = 'REFSET';
	my $sequtils = Sequence->new();
	my $extract_len = $extract_stop - $extract_start;

	# Get the GLUE header section and info
	my @raw_fasta = <INFILE>;
	close INFILE;
	my $got_header = undef;
	my $refseq     = undef;
	my $start  = undef;
	my $stop   = undef;
	foreach my $line (@raw_fasta) {

		if ($line =~ /^\s*$/) { 
			shift @raw_fasta; # discard blank line
			next; 
		} 
		if ($line =~ /^#GLUE/) { 
			$got_header = 1;
			my @line = split(/\s+/, $line);
			#$devtools->print_array(\@line); die;
			$refseq = $line[1];
			my $coordinates = $line[2];
			my @coordinates = split(/-/, $coordinates);
			$start = shift @coordinates;
			$stop  = shift @coordinates;
			shift @raw_fasta; # discard header line
			last;
		}
	}
	unless ($got_header) {
		return "\n\t This does not look like a GLUE file\n\n";
	}	

	# Check validity of coordinates
	my $invalid_splice  = undef;
	if ($start) {
		if ($extract_start >= $stop) { $invalid_splice = 1; }
	}
	if ($stop) {
		if ($extract_stop <= $start) { $invalid_splice = 1; }
	}
	if ($invalid_splice) {
		return "\n\t Invalid splice coordinates for this MSA\n\n";
	}

	# Adjust coordinates based on reference sequences
	my $adjust_start = ($extract_start - $start) + 1;	
	my $adjust_stop  = ($extract_stop - $start) + 1;	
	
	# Iterate through remaining lines in the file, which should contain FASTA formatted sequences
	my $header;
    my $sequence;
   	my $i = 0;
   	my $skipped_refs = 0;
	my @sequences;
	foreach my $line (@raw_fasta) {
		
		chomp $line;
		if    ($line =~ /^\s*$/)   { next; } # discard blank line
		elsif ($line =~ /^\s*#/)   { next; } # discard comment line 
		elsif ($line =~ /^>/) {
			
			$line =~ s/^>//g;
					
			# new header, store any sequence held in the buffer
			if ($header and $sequence) {
				#print "\n\t\t # Loading GLUE Sequence $i";
				$i++;
				my $alias_id = $alias_stem . '_' .  $i;
				$sequence = uc $sequence;
				#print "\n\t ### Extracting subsequence";
				#print "\n\t ### MSA:     $start\t$stop";
				#print "\n\t ### Extract: $extract_start\t$extract_stop";
				#print "\n\t ### Adjust:  $adjust_start\t$adjust_stop";
				my $subseq  = $sequtils->extract_subsequence($sequence, $adjust_start, $adjust_stop);
				
				my $check = $subseq;
				$check =~ s/-//g;
				my $new_len = length $check;
				my $coverage = $new_len / $extract_len;
				if ($coverage < $coverage_minimum)  {
					#print "Ratio: $coverage = ($new_len / $extract_len) too short";
					$skipped_refs++;
					next;
				}
				else {
					my $seq_obj = Sequence->new($subseq, $header, $alias_id);
					push(@sequences, $seq_obj);
				}
			}
		
			# reset the variables 
			$line =~ s/^>//;
			$header = $line;
			$sequence = undef;
		}
		else {
			# keep line, add to sequence string
            $sequence .= $line;
     	}
    }
	
	# Before exit, store any sequence held in the buffer
	if ($header and $sequence) {
		$i++;
		my $alias_id = $alias_stem . $i;
		$sequence =~ s/\s+//g; # Remove whitespace
		$sequence = uc $sequence;
		#print "\n\t ### Extracting subsequence";
		#print "\n\t ### MSA:     $start\t$stop";
		#print "\n\t ### Extract: $extract_start\t$extract_stop";
		#print "\n\t ### Adjust:  $adjust_start\t$adjust_stop";
		my $subseq  = $sequtils->extract_subsequence($sequence, $adjust_start, $adjust_stop);
	
		my $check = $subseq;
		$check =~ s/-//g;
		my $new_len = length $check;
		my $coverage = $new_len / $extract_len;
		if ($coverage < $coverage_minimum)  {
			#print "Ratio: $coverage = ($new_len / $extract_len) too short";
			$skipped_refs++;
		}
		else {
			my $seq_obj = Sequence->new($subseq, $header, $alias_id);
			push(@sequences, $seq_obj);
		}
	}

	# Store the MSA data
	$hash_ref->{refalign_sequences} = \@sequences;
	$hash_ref->{refalign_start}     = $start;
	$hash_ref->{refalign_stop}      = $stop;
	$hash_ref->{refalign_refseq}    = $refseq;
	$hash_ref->{skipped_refs}       = $skipped_refs;
	#$devtools->print_array(\@sequences); die;
	
	return 0;
}
#***************************************************************************
# Subroutine:  convert_fasta
# Description: convert an array of FASTA (text) to an array of Sequence objects
# Arguments: $fasta_ref: reference to array containing FASTA formatted data
#            $array_ref: reference to the hash array to copy to
#***************************************************************************
sub convert_fasta {

	my ($self, $fasta_ref, $array_ref) = @_;
	
	# Use process ID and time to create unique ID stem
	my $pid  = $$;
	my $time = time;
	my $alias_stem = $pid . '_' . $time . '_';
	
	# Iterate through lines in the file
	close INFILE;
	my $header;
    my $sequence;
   	my $i = 0;
	foreach my $line (@$fasta_ref) {
		
		chomp $line;
		#$line =~ s/\s+//g; # Remove whitespace
		if    ($line =~ /^\s*$/)   { next; } # discard blank line
		elsif ($line =~ /^\s*#/)   { next; } # discard comment line 
		elsif ($line =~ /^>/) {
			
			$line =~ s/^>//g;
					
			# new header, store any sequence held in the buffer
			if ($header and $sequence) {
				$i++;
				my $alias_id = $alias_stem . $i;
				$sequence = uc $sequence;
				#print "\n\t HERE '$header'";
				my $seq_obj = Sequence->new($sequence, $header, $alias_id);
				push(@$array_ref, $seq_obj);
			}
		
			# reset the variables 
			$header = $line;
			$sequence = undef;
		}
		else {
			# keep line, add to sequence string
            $sequence .= $line;
     	}
    }
	
	# Before exit, store any sequence held in the buffer
	if ($header and $sequence) {
		$i++;
		my $alias_id = $alias_stem . $i;
		$sequence = uc $sequence;
		#print "\n\t HERE '$header'";
		my $seq_obj = Sequence->new($sequence, $header, $alias_id);
		push(@$array_ref, $seq_obj);
	}
}

#***************************************************************************
# Subroutine:  write fasta 
# Description: write FASTA
#***************************************************************************
sub write_fasta {

	my ($self, $file, $sequences_ref) = @_;

	my @fasta;
	foreach my $sequence_ref (@$sequences_ref) {
	
		my $id       = $sequence_ref->{header};
		my $sequence = $sequence_ref->{sequence};
		my $fasta = ">$id\n$sequence\n\n";
		#print "\n$fasta\n";
		push (@fasta, $fasta);
	}
	$fileio->write_file($file, \@fasta);
}

#***************************************************************************
# Subroutine:  write delimited
# Description: write sequence data to tab-delimited
#***************************************************************************
sub write_delimited {

	my ($self, $file, $data_ref, $exclude_seq) = @_;

	# Create column headings & check consistency
	#$devtools->print_array($data_ref); die;
	my %fields;
	my $i = 0;
	foreach my $hash_ref (@$data_ref) {
		my @fields = keys %$hash_ref;
		foreach my $field (@fields) {
			if ($i > 1) {
				# Skip fields that are not defined in first row
				unless ($fields{$field}) { next; } 
			}
			else {
				$fields{$field} = 1;
			}
		}
	}

	# Set up the fields for writing the file
	my @fields = keys %fields;
	my @ordered_fields;
	push (@ordered_fields, 'sequence_id');
	foreach my $field (@fields) {
		if ($field eq 'sequence_id') { next; }
		elsif ($field eq 'sequence') { next; }
		else {
			push (@ordered_fields, $field);
		}
	}
	unless ($exclude_seq) {
		push (@ordered_fields, 'sequence');
	}
	
	# Add column headings
	my $header_line = join("\t", @ordered_fields);
	my @data;
	push (@data, "$header_line\n");

	# Create the file
	foreach my $hash_ref (@$data_ref) {
		my @line;
		
		foreach my $field (@ordered_fields) {
			my $value = $hash_ref->{$field};
			unless ($value) {
				$value = 'NULL';
				if ($field eq 'sequence') {
					$value = 'NULL1';
					print "\n\t ## Warning - empty sequence field"; 
				}
				elsif ($field eq 'sequence_id') {
					$value = 'NULL2';
					print "\n\t ## Warning - empty seq ID field"; 
				}
			}
			push (@line, $value);
		}
		my $line = join("\t", @line);
		push (@data, "$line\n");
	}
	$fileio->write_file($file, \@data);
}

############################################################################
# END OF FILE 
############################################################################

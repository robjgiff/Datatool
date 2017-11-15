#!/usr/bin/perl -w
############################################################################
# Script:      fasta to phylip
############################################################################

############################################################################
# Import statements/packages (externally developed packages)
############################################################################
use strict;

############################################################################
# Globals
############################################################################
my $set_id_len = 35;
my ($USAGE) = "\n\t$0 [file]\n\n";

###########################################################################
# Begin main script 
###########################################################################

# Main program loop
#show_title();
my $file = $ARGV[0];
unless ($file) { die $USAGE; }
fasta_to_phylip($file);
exit;


############################################################################
# Subroutines
############################################################################

#***************************************************************************
# Subroutine:  fasta_to_phylip
# Description: 
#***************************************************************************
sub fasta_to_phylip {

	my ($file) = @_;
	
	my @fasta;
	read_fasta_to_array($file, \@fasta);

	my @table;
	my @phylip;
	my $phycount;
	my $seq_len;
	foreach my $sequence_ref (@fasta) {
		
		$phycount++;
		my $sequence_id = $sequence_ref->{header};
		my $sequence    = $sequence_ref->{sequence};
		unless ($seq_len) {
			$seq_len = length $sequence;
		}
		else {
			unless ($seq_len eq length $sequence) {
				die "\n\t sequence $sequence_id is a different length\n
				       \t check FASTA sequences are aligned\n\n";
			}
		}
	
		# Create phylip id
		#my $phy_id = $phycount . '_'; 
		my $phy_id;
		my @sequence_id = split ('', $sequence_id);
		my $id_len;
		my $set_len = $set_id_len - 5; 
		foreach my $char (@sequence_id) {
			$phy_id .= $char;	
			$id_len = length($phy_id);
			if ($id_len eq $set_len) { last; }
		}
		my $spacer_len = ($set_id_len - $id_len);
		my $spacer = ' ' x $spacer_len;
		my $phy_seq = $phy_id . $spacer . $sequence . "\n";
		push(@phylip, $phy_seq);
		
		# store id relationship in translation table 
		my $id_pair = "$sequence_id\t$phy_id\n";
		push (@table, $id_pair);
	
	}
	
	# Create PHYLIP taxa and characters header
	my $num_taxa  = $phycount;
	my $num_chars = $seq_len;
	my $header_line = $num_taxa . '   ' . $num_chars . "\n";
	unshift(@phylip, $header_line);
	
	my $outfile = $file . '.phy';
	write_output_file($outfile, \@phylip);
	my $table_file = $file . '_translation_tab.txt';
	write_output_file($table_file, \@table);

}


#***************************************************************************
# Subroutine:  read_fasta_to_array
# Description: read a fasta file into an array of hashes, so that the headers 
#              are stored by key 'header' and the sequences with key 'sequence'
# Arguments:   $file: the name of the file to read
#              $array_ref: reference to the hash array to copy to
#***************************************************************************
sub read_fasta_to_array {

	my ($file, $array_ref) = @_;

	# Convert mac line breaks
	my $command = "perl -pi -e 's/\r/\n/g' $file";
	system $command;
	
	unless (open(INFILE, $file)) {
		print "\n\t Cannot open file \"$file\"\n\n";
		return undef;
	}

	my @raw_fasta = <INFILE>;
	close INFILE;

	my $header;
    my $sequence;
    foreach my $line (@raw_fasta) {

		# Remove whitespace
		$line =~ s/\r/\n/g;
		$line =~ s/\s+//g;
		
		if    ($line =~ /^\s*$/)   { next; } # discard blank line
		elsif ($line =~ /^\s*#/)   { next; } # discard comment line 
		elsif ($line =~ /^>/) {
			
			$line =~ s/^>//g;
					
			# new header, store any sequence held in the buffer
			if ($header and $sequence) {
				my %sequence;
				$sequence{header}   = $header;
				$sequence{sequence} = uc $sequence;
				push(@$array_ref, \%sequence);
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
		my %sequence;
		$sequence{header}   = $header;
		$sequence{sequence} = uc $sequence;
		push(@$array_ref, \%sequence);
	}

	# to do: incorporate error checking in 'success'
	# e.g. do num seqs match num chevrons?
	my $success = 1;
	return $success;
}


#***************************************************************************
# Subroutine:  write_output_file
# Description: write an array to an ouput file
# Arguments:   $file: the name of the file to write to 
#              $array_ref: array to copy
#***************************************************************************
sub write_output_file {

	my ($file, $array_ref) = @_;
	unless (open(OUTFILE, ">$file")) {
		print "\n\t Couldn't open file \"$file\" for writing\n\n";
		return;
	}
	print OUTFILE @$array_ref;
	close OUTFILE;
	print "\n\t File \"$file\" created!\n\n";
}


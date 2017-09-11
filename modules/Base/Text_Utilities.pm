#!/usr/bin/perl -w
############################################################################
# Script:      Text_Utilities 
# Description: An object providing generic functions for writing formatted
#              text output
# History:     (Rob Gifford) December 2006: Creation
# Details:
############################################################################
package Text_Utilities;

############################################################################
# Import statements/packages (externally developed packages)
############################################################################
use strict;

############################################################################
# Import statements/packages (internally developed packages)
############################################################################

# Base Classes
use Base::FileIO;
use Base::DevTools;
use Base::Console;
use Base::Core;

############################################################################
# Globals
############################################################################
my $devtools = DevTools->new();
my $fileio  = FileIO->new();
1;

############################################################################
# LIFECYCLE
############################################################################

#***************************************************************************
# Subroutine:  new
# Description: create a new Text_Utilies object 
# Arguments:   $raw_input: reference to an array containing raw fasta data 
#                          with headers as keys and sequnces as values
#***************************************************************************
sub new {

	my ($invocant, $parameters) = @_;
	my $class = ref($invocant) || $invocant;

	# Member variables
	my $self = {
	};

	bless ($self, $class);
	return $self;
}

############################################################################
# Public Member Functions
############################################################################

#***************************************************************************
# Subroutine:  create_text_header
# Description: prints a formatted header using '#' chars
#***************************************************************************
sub create_text_header {
    
	my ($self, $title, $size) = @_;
    if (length($title) + 8 > $size) { 
		die "In PrintHeader: $title title length > title size"; 
	}
    my $lead_space = int (($size - length($title) - 2) / 2);
    my $trail_space = 80 - ($lead_space + length($title) + 2);
    my $text =  "\n\n\n" . '*' x 80 . "\n";
    $text .= '*' x $lead_space . " " . $title . " " . '*' x $trail_space;
    $text .= "\n" . '*' x 80 . "\n";
    return $text;
}

#***************************************************************************
# Subroutine:  create_table
# Description: 
#***************************************************************************
sub create_table {
    
	my ($self, $parameters_ref, $data_ref, $output_ref) = @_;
	
	# Use the data to create 
	my %table;
	$self->create_table_hash($parameters_ref, $data_ref, \%table);
	
	# DEBUG
	#$devtools->print_hash(\%table);
	
	# Convert the table hash to formatted output
	my $num_rows = scalar @$data_ref;
	$parameters_ref->{num_rows} = $num_rows;
	$self->convert_table_hash_to_table($parameters_ref, \%table, $output_ref);
	
	# DEBUG
	$devtools->print_array($output_ref);
	# DEBUG
	$fileio->write_output_file('zzz.out', $output_ref);
	exit;
}

#***************************************************************************
# Subroutine:  create_table_hash
# Description: 
#***************************************************************************
sub create_table_hash {
    
	my ($self, $parameters_ref, $data_ref, $hash_ref) = @_;
	
	# Get formatting parameters
	my $total_width   = $parameters_ref->{total_width};

	# Use data to set up indexed matrix hash to represent table
	my $row_index;
	foreach my $line (@$data_ref) {
		$row_index++;
		my @row_data = split("\t", $line);
		my %row;
		
		my $column_index;
		foreach my $item (@row_data) {
			$column_index++;
			my $format_ref = $parameters_ref->{$column_index};
			
			my $width     = $format_ref->{width};
			my $token     = $format_ref->{token};
			my $left_pad  = $format_ref->{left_pad};
			my $right_pad = $format_ref->{right_pad};
			my @item  = split("$token", $item); 
			
			my $line_num = 0;
			my $tab_line = $left_pad;
			
			# For keeping track fo multiple lines
			my @row_lines;
			my $line_index++;
			foreach my $chunk (@item) {
				
				# Check length
				my $chunk_len      = length($chunk);
				if ($chunk_len > $width) {
					#print "\n\t $chunk_len > $width";
					die "\n\t Value '$chunk' too long for column\n\n";
				}
				
				my $line_len       = length($tab_line);
				my $right_pad_len  = length($right_pad);
				my $total_len = $line_len + $chunk_len + $right_pad_len;
				
				if ($total_len > $width) {
					my $width_left = $width - $line_len;
					my $right_padder = ' ' x $width_left;
					$tab_line .= $right_padder;
					push (@row_lines, $tab_line);
					$tab_line = $left_pad . $chunk . $token;
				}
				else {
					$tab_line .= $chunk . $token;
				}
			}
			if ($tab_line) {
				my $line_len = length($tab_line);
				my $width_left = $width - $line_len;
				my $right_padder = ' ' x $width_left;
				$tab_line .= $right_padder;
				push (@row_lines, $tab_line);
			}
			
			$row{$column_index} = \@row_lines;
		}
		$hash_ref->{$row_index} = \%row;
	}
}

#***************************************************************************
# Subroutine:  create_table_hash
# Description: prints a formatted header using '#' chars
#***************************************************************************
sub convert_table_hash_to_table {
    
	my ($self, $parameters_ref, $hash_ref, $output_ref) = @_;
	
	# Get number of columns and rows
	my $num_columns = $parameters_ref->{num_columns};
	my $num_rows    = $parameters_ref->{num_rows};
	my $total_width = $parameters_ref->{total_width};
	my $offset_len  = $parameters_ref->{offset};
	my $offset = ' ' x $offset_len;
	
	# Now write the table
	my @columns = 1..$num_columns;
	my @rows    = 1..$num_rows;
	foreach my $row_index (@rows) {
		
		# Format the row over however many lines
		#print "\n\t Doing row $row_index";	
		my $row_ref  = $hash_ref->{$row_index};
		
		my $finished = undef;
		my @line;	
		my $line_index = 0;
		do {
			
			# get column values for this line of the row
			my $got_lines = undef;
			foreach my $column_index (@columns) {
				
				#print "\n\t Doing column $column_index";	
				
				my $lines_ref = $row_ref->{$column_index};
				my $format_ref = $parameters_ref->{$column_index};
				my $width      = $format_ref->{width};
				
				if (@$lines_ref[$line_index]) {
					my $element = @$lines_ref[$line_index];	
					push (@line, $element);
					$got_lines = 'true';
				}
				else {
					my $element = ' ' x $width;
					push (@line, $element);
				}
			}	
			
			if ($got_lines) {
				
				my $num_elements = scalar @line;
				#print "\n Line $line_index: has $num_elements elements";
				my $internal = join('|', @line);
				my $total  = $offset . '|' . $internal . '|' . "\n";
				#print "\n Line $line_index: $total";
				push (@$output_ref, $total);
				@line = ();
			}
			# Unless one column had values we are finished
			else { $finished = 'true'; }

			# Increment the line index
			$line_index++;
		
		} until ($finished);
	}
	#$devtools->print_array($output_ref);
}

############################################################################
# END OF FILE
############################################################################

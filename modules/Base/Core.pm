#!/usr/bin/perl -w
############################################################################
# Script:       Core.pm 
# Description:  
# History:      Rob Gifford, Novemeber 2006: Creation
############################################################################
package Core;

############################################################################
# Import statements/packages (externally developed packages)
############################################################################
use strict;

############################################################################
# Import statements/packages (internally developed packages)
############################################################################

# Base Modules
use Base::DevTools;
use Base::BioIO;

############################################################################
# Globals
############################################################################
my $fileio    = FileIO->new();
my $devtools  = DevTools->new();
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
# Subroutine:  pivot 
# Description: 
#***************************************************************************
sub pivot {

	my ($self, $file1_ref, $output_ref) = @_;
	

	die;  # FXN BROKEN
	my %data;
	my $number_lines = 0;
	my $column_number = 0;
	foreach my $line (@$file1_ref) {
	
		chomp $line;
		$column_number++;
		my @data = split ("\t", $line);
		unless ($number_lines) {
			$number_lines = scalar @data;
		}
		$data{$column_number} = \@data;
	}
	
	my @line_range = 1..$number_lines;
	foreach my $line_index (@line_range) {
		
		print "\n\tcolumn $line_index from line $line_index";	
		my @output_line;
		my $data_ref = $data{$line_index};
		my $i = 0;
		do {
			my $value = @$data_ref[$i];	
			push(@output_line, $value);
			$i++;
		} until ( $i eq  scalar @$data_ref);
		my $output_line = join("\t", @output_line);
		push(@$output_ref, "$output_line\n")
	}
}

#***************************************************************************
# Subroutine:  
# Description: split a string (a sequence generally) into chars and create 
#              a hash with the position (index) of the char as the key and 
#              the char as the value
# To do: Move this function into a more general untility object
#***************************************************************************
sub string_to_indexed_hash {

	my ($self, $string, $hash_ref, $start, $stop) = @_;

	unless ($start) { $start = 1; } 
	unless ($stop)  { $stop  = length $string; } 

	my @array = split ('', $string);
	my $count_index = 0;
	my $key_index   = 0;
	foreach my $element (@array) {
		$count_index++;
		if ($count_index >= $start and $count_index <= $stop) {
			$key_index++;
			$hash_ref->{$key_index} = $element;
		}
	}
}

#***************************************************************************
# Subroutine:  
# Description: split a string (a sequence generally) into chars and create 
#              a hash with the position (index) of the char as the key and 
#              the char as the value
# To do: Move this function into a more general untility object
#***************************************************************************
sub string_to_indexed_hash2 {

	my ($self, $string, $hash_ref, $start) = @_;

	unless ($start) { $start = 1; } 
	my @array = split ('', $string);
	my $count_index = $start;
	foreach my $element (@array) {
		$hash_ref->{$count_index} = $element;
		$count_index++;
	}
}

#***************************************************************************
# Subroutine:  hash to array
# Description: convert a hash to an array with the hash data formatted as 
#              delimited values, useful to format a hash for output. 
# Arguments:   $hash_ref, $array_ref, $delimiter 
#***************************************************************************
sub hash_to_array {

	my ($self, $hash_ref, $array_ref, $delimiter) = @_;

	my $key;
	my $value;
	while ( ( $key, $value ) = each %$hash_ref ) {
		my $output = $key . $delimiter . $value . "\t";
		push (@$array_ref, $output);
	}
}

#***************************************************************************
# Subroutine:  sort_hash_of_hash_by_hashvalue
# Description: 
# Arguments:   $array_ref, $hash_ref, $hashfield
#***************************************************************************
sub sort_hash_of_hash_by_hashvalue_desc {

	my ($self, $array_ref, $hash_ref, $hashfield) = @_;

	# first create a simple hash
	my %flat_hash;
	my $key;
	my $internal_hash_ref;
	while ( ( $key, $internal_hash_ref ) = each %$hash_ref ) {
		
		unless ($internal_hash_ref->{$hashfield}) {
			die "\n\t Hash did not contain field '$hashfield'\n\n";
		}
		my $value = $internal_hash_ref->{$hashfield};
		$flat_hash{$key} = $value;
	}
	
	# Now sort the hash
	my @sorted_hashes;
	foreach my $key (sort {$flat_hash{$b} <=> $flat_hash{$a}} keys %flat_hash) {
		#print "\n\t$key :  $flat_hash{$key}";
		my $internal_hash_ref = $hash_ref->{$key};
		push(@$array_ref, $internal_hash_ref);
	}
	
}

############################################################################
# To read, review and comment
############################################################################

#***************************************************************************
# Subroutine:  
# Description: 
# To do: Move this function into a more general untility object
#***************************************************************************
sub tabdelim_array_to_indexed_hash {

	my ($self, $array_ref, $hash_ref, $field_index) = @_;

	my $i = 0;
	foreach my $row (@$array_ref) {
		
		chomp $row;
		
		$i++;
		my @row = split("\t", $row);
		my $index_value = $row[$field_index];
		
		unless ($index_value) {
			die "\n\t no index value at line $i";
		}
		if ($hash_ref->{$index_value}) {
			die "\n\t repeat of index value '$index_value' at line $i";
		}
	
		$hash_ref->{$index_value} = $row;
	
	}
}

#***************************************************************************
# Subroutine:  
# Description: 
#***************************************************************************
sub tabdelim_array_to_indexed_hash2 {

	my ($self, $array_ref, $hash_ref, $field_index) = @_;

	my $i = 0;
	foreach my $row (@$array_ref) {
		
		chomp $row;
		
		$i++;
		my @row = split("\t", $row);
		my $index_value = $row[$field_index];
		
		unless ($index_value) {
			die "\n\t no index value at line $i";
		}
		if ($index_value eq 1) { next; }
		else { $index_value = $index_value + 1; }
		
		if ($hash_ref->{$index_value}) {
			my $hash_array_ref = $hash_ref->{$index_value};
			push (@$hash_array_ref, $row);
		}
		else {
			my @array;
			push (@array, $row);
			$hash_ref->{$index_value} = \@array;
		}
	}
}

#***************************************************************************
# Subroutine:  join_hashes_with_rule
# Description: 
# To do: Move this function into a more general untility object
#***************************************************************************
sub join_hashes_with_rule {

	my ($self, $array_ref, $hash_ref1, $hash_ref2, $rule_field) = @_;
	
	my $hash_index;
	my $index_data;
	while ( ( $hash_index, $index_data ) = each %$hash_ref1) {

		my $match_array_ref = $hash_ref2->{$hash_index};
		my $chosen_data;
		my $highest_field = 0;
		foreach my $row (@$match_array_ref) {
			
			my @row = split("\t", $row);
			my $value = $row[$rule_field];
			if ($value > $highest_field) {
				$chosen_data = $row;
				$highest_field = $value; 
			}
		}
		my $joined_data = $index_data . "\t" . $chosen_data . "\n";;
		push (@$array_ref, $joined_data);
	}
}

############################################################################
# Title etc
############################################################################

#***************************************************************************
# Subroutine:  convert_tabdelim_to_hash_of_hash
# Description: 
# Arguments:   
#***************************************************************************
sub convert_tabdelim_to_array_of_hash {

	my ($self, $tabdelim_ref, $array_ref) = @_;

	# Get the column headings (remove from array with shift)
	my $column_headings = shift @$tabdelim_ref;
	chomp $column_headings;
	unless ($column_headings) { return; }
	my @column_headings = split("\t", $column_headings);
	
	# Iterate through the remaining data
	#print_array($tabdelim_ref);
	foreach my $line (@$tabdelim_ref) {
		
		my @values = split("\t", $line);
		
		# Iterate through fields and get the data
		my %data;
		my $index = 0;
		foreach my $value (@values) {
			my $field = $column_headings[$index];
			$data{$field} = $values[$index];;
			$index++
		}
		push (@$array_ref, \%data);
	}
}

#***************************************************************************
# Subroutine:  convert_csv_to_hash_of_hash
# Description: 
# Arguments:   
#***************************************************************************
sub convert_csv_to_array_of_hash {

	my ($self, $csv_ref, $array_ref) = @_;

	# Get the column headings (remove from array with shift)
	my $column_headings = shift @$csv_ref;
	chomp $column_headings;
	unless ($column_headings) { return; }
	my @column_headings = split(",", $column_headings);
	
	# Iterate through the remaining data
	#print_array($csv_ref);
	foreach my $line (@$csv_ref) {
		
		chomp $line;
		next if ($line =~ /^\s+$/);
		
		my @values = split(",", $line);
		
		# Iterate through fields and get the data
		my %data;
		my $index = 0;
		foreach my $value (@values) {
			my $field = $column_headings[$index];
			if ($field) {
				$field =~ s/"//g;
				my $value = $values[$index];
				if ($value) {
					$value =~ s/"//g;
					$data{$field} = $value;
				}
			}
			$index++;
		}
		push (@$array_ref, \%data);
	}
}




#***************************************************************************
# Subroutine:  convert_array_of_hash_to_tabdelim 
# Description: 
# Arguments:   
#***************************************************************************
sub convert_array_of_hash_to_tabdelim {

	my ($self, $array_ref, $tabdelim_ref, $column_ref) = @_;

	# create the column headings
	my @column_headings;
	foreach my $heading (@$column_ref) {
		push (@column_headings, $heading);
	}
	my $header_line = join("\t", @column_headings);
	push (@$tabdelim_ref, "$header_line\n");

	# Iterate through array of hashes
	foreach my $hash_ref (@$array_ref) {
		
		# Iterate through column headings	
		my @values;
		foreach my $field (@column_headings) {
			my $value = $hash_ref->{$field};	
			#print "\n\t got value '$value' for field '$field'";
			push(@values, $value);
		}
		my $data = join("\t", @values);
		push (@$tabdelim_ref, "$data\n");
	}
}

############################################################################
# Basic utility calculations
############################################################################

#***************************************************************************
# Subroutine:  get precentage 
# Description: convert fraction to percentage
# Arguments:   the numerator and denominator of the fraction as scalars
#***************************************************************************
sub get_percentage {

	my ($self, $numerator, $denominator) = @_;

	if ($numerator > $denominator) {

		print  "\n Somethings wrong here...";
		print  "\n Numerator:   $numerator";
		print  "\n Denominator: $denominator\n\n";
		die;
	}

	# To do: is this the best solution to divide by zero....?
	unless ($denominator > 0) { return '0'; }
	my $percentage = (($numerator / $denominator) * 100);
	return $percentage;
}

############################################################################
# Module:  make matrix
# Description: 
# Arguments:   
# History: Created by Robert Gifford, July 2005 <robjgiff@gmail.com>
############################################################################
sub make_matrix {

	my ($self, $file_ref, $v_index, $h_index) = @_;

	# do the matrix
	my %matrix;
	my %vertical;
	my %horizontal;
	foreach my $line (@$file_ref) {

		# get values
		my @line = split("\t", $line);
		my $v_result = $line[$v_index];
		chomp $v_result;
		my $h_result = $line[$h_index];
		chomp $h_result;
	
		# intialise matrix indices
		unless ($vertical{$v_result})   { $vertical{$v_result} = 1;   } 
		unless ($horizontal{$h_result}) { $horizontal{$h_result} = 1; } 

		# increment appropriate matrix position
		my $key = $v_result . ':' . $h_result;
		$matrix{$key} = ($matrix{$key} + 1);

	}

	#$devtools->print_hash(\%matrix);
	#$devtools->print_hash(\%vertical);
	#$devtools->print_hash(\%horizontal);
}


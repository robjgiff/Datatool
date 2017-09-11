#!/usr/bin/perl -w
############################################################################
# Script:      data_tool.pl 
# Description: a collection of tools for working with sequences + data
# History:     Version 1.0 Creation: Rob J Gifford 2014
############################################################################

# use a local modules for this program (for portability)
use lib './modules/'; 

############################################################################
# Import statements/packages (externally developed packages)
############################################################################
use strict;
use CGI;
use Getopt::Long;

############################################################################
# Import statements/packages (internally developed packages)
############################################################################

# Base modules
use Base::Console;
use Base::DevTools;
use Base::FileIO;
use Base::SeqIO;

# GLUE program modules
use GLUE::DataTool;
use GLUE::DataToolCmd;
use GLUE::RefSeq;
use GLUE::RefSeqParser;

############################################################################
# Paths
############################################################################

############################################################################
# Globals
############################################################################

# Version number
my $program_version = '1.0 beta';

# Process ID and time - used to create a unique ID for each program run
my $pid  = $$;
my $time = time;

# Create a unique ID for this process
my $process_id   = $pid . '_' . $time;
my $user = $ENV{"USER"};

# Paths
my $output_path           = './output/';     # Reports
my $refseq_use_path       = './db/refseq_flat/';   # RefSeq flat directory

############################################################################
# Instantiations for program 'classes' (PERL's Object-Oriented Emulation)
############################################################################

# Base utilites
my $seqio      = SeqIO->new();
my $fileio     = FileIO->new();
my $devtools   = DevTools->new();
my $console    = Console->new();

# Data tool
my %tool_params;
$tool_params{process_id}  = $process_id;
$tool_params{output_type} = 'text';  # Default is text
$tool_params{output_path} = $output_path;
$tool_params{refseq_use_path} = './db/refseq/';
my $datatool = DataTool->new(\%tool_params);
$tool_params{datatool_obj} = $datatool;
my $cmd_line_interface = DataToolCmd->new(\%tool_params);

############################################################################
# Set up USAGE statement
############################################################################

# Initialise usage statement to print if usage is incorrect
my ($USAGE) = "\n\t  usage: $0 -[options]\n\n";

############################################################################
# Main program
############################################################################

# Run script
$console->refresh();
main();

# Exit program
exit;

############################################################################
# Subroutines
############################################################################

#***************************************************************************
# Subroutine:  main
# Description: top level handler fxn
#***************************************************************************
sub main {

	# Define options
	my $help         = undef;
	my $version      = undef;
	my $mode		 = undef;
	my $sort		 = undef;
	my $special		 = undef;
	my $file1        = undef;
	my $file2        = undef;
	my $dir          = undef;

	# Read in options using GetOpt::Long
	GetOptions ('help!'               => \$help,
                'version!'            => \$version,
				'mode|m=i'            => \$mode,
				'sort|s=i'            => \$sort,
				'special|x=i'         => \$special,
				'infile|i=s'          => \$file1,
				'comfile|c=s'         => \$file2,
				'dir|d=s'             => \$dir,
	);

	if ($help)    { # Show help page
		$cmd_line_interface->show_help_page();  
	}
	elsif ($version)  { 
		print "\n\t # GLUE datatool.pl version $program_version\n\n";  
	}
	elsif ($mode and $file1
	   or  $mode and $dir) { # Data reformatting tools
		my $result = $cmd_line_interface->run_reformat_tools_cmd_line($file1, $dir, $mode);
	}
	elsif ($sort) { # Data sorting tools
		$cmd_line_interface->run_sort_tools_cmd_line($file1, $file2, $sort);
	}
	elsif ($special) { # Bespoke case sorting tools
		$cmd_line_interface->run_special_tools_cmd_line($file1, $special);
	}
	else {
		die $USAGE;
	}
	print "\n\n\t # Exit\n\n\n";
}

############################################################################
# EOF
############################################################################

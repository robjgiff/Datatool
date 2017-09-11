# Datatool

**Miscellaneous tools for working with molecular sequence data.**

data_tool.pl provides utilities for manipulating and sorting FASTA files:


```

	 usage: ./data_tool.pl -m[options] -s[options] -i[infile] -c[comparison file] -d[directory]

	 # Convert between formats
	  -m=1   :   FASTA to Delimited
	  -m=2   :   Delimited to FASTA
	  -m=3   :   Genbank to FASTA+DATA
	  -m=4   :   NCBI refseq FASTA to DIGS input
	  -m=5   :   REFSEQ to FASTA
	  -m=6   :   REFSEQ to Se-Al-friendly FASTA
	  -m=7   :   REFSEQ features to GLUE (java version) feature table
	  -m=8   :   FASTA to NEXUS
	  -m=9   :   FASTA to PHYLIP
	  -m=10  :   REFSEQ to linear formatted

	 # Sorting, filtering, linking
	  -s=1   :   Shorten FASTA headers
	  -s=2   :   Sort sequences by length
	  -s=3   :   Filter sequences by keyword
	  -s=4   :   Link two data files using a shared ID
	  -s=5   :   Sort sequences by data column

	 # Exit


```

Warning: BETA VERSIONS, THESE SCRIPTS MAY CONTAIN BUGS ETC. 


ncbi_fetch.pl is a script for retrieving data from NCBI

```
  	usage: ncbi_fetch.pl -r report -q query -o output -d database

	# Example ./ncbi_fetch.pl -r gb -q "Hepatitis C Virus"[Organism] -o HCV_all_genbank.gb -d Nucleotide

```


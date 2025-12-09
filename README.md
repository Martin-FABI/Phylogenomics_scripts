## The following files are bash / python files that can be used in a typical phylogenomic study:

01_gather_buscos.sh

01_headers_rename.sh - Remove all characters after first "|"

02_align.sh - MAFFT alignments

03_trim.sh - TrimAL

04_filter.sh - Filter sequences < x after trimming

05_concat_iqtree.sh - Concatenate datasets and generate a maximum likelihood tree using IQtree

06_gene_trees.sh - Generate seperate genetrees, and then combine them in one file

07_astral.sh - Generate a Supertree using ASTRAL or ASTER

08_all_in_one_concordance_factor.sh - Generate species tree, gene trees and concordance factor.
 Note that you will need the following:
  1. Supermatrix (concatentated MSA file).
  2. Single gene alignments in a seperate folder.
  3. Partition file (can be in nexus format or RAXML format)

For a nice description see: https://www.robertlanfear.com/blog/files/concordance_factors.html

10_msa_outlier.py - Python script that detects outliers in a MSA (this is a work in progress)

Note: All scripts to automate processess were developed by MPA Coetzee with the help of ChatGPT 5 (Thinking module)

## DATASET: 

busco_data.zip

## INFORMATION:

Short versions of the code and other information are available in the file: Commdands_short_version.txt



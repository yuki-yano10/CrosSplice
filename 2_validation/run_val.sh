#!/bin/bash
#$ -S /usr/bin/bash
#$ -pe def_slot 4
set -xeuo pipefail

WDIR="/path/to/working_directory"
INPUT="$WDIR/output/cross_input.merge.txt"
OUTPUT_VALIDATION="$WDIR/output/cross.validation2.txt"
VCF_37="/path/to/original/vcf"  #put the original vcf file befored devided
PROCESSES=4
MODE="lift"  #If your original vcf file is GRCh37, set "lift", then the script uses mutkey_38lift37.py. If you do not need liftover, set "direct", then mutkey_38direct.py is used. 
CHAIN="/path/to/hg38ToHg19.over.chain"  #Put "NONE" if you do not need liftover.
SJOUT_TAB="/path/to/sjouttab_list.txt"

bash 2_validation/run.sh ${INPUT} ${OUTPUT_VALIDATION} ${VCF_37} ${PROCESSES} ${MODE} ${CHAIN} ${SJOUT_TAB}

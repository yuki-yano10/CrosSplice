#!/bin/bash
#$ -S /usr/bin/bash
#$ -pe def_slot 4
set -xeuo pipefail

WDIR=/home/yano_y/GTEX_validation_project/cros_test
INPUT=$WDIR/output_direct/cross_input.merge.txt
OUTPUT_VALIDATION=$WDIR/output_direct/cross.validation3.txt
VCF_37=/home/yano_y/GTEX_validation_project/cros_test/vcf/sample.lift38.22.vcf.gz  #put the original vcf file befored devided
PROCESSES=4
MODE="direct"  #If your original vcf file is GRCh37, set "lift", then the script uses mutkey_38lift37.py. If you do not need liftover, set "direct", then mutkey_38direct.py is used. 
CHAIN=NONE  #Put "NONE" if you do not need liftover.
SJOUT_TAB=/home/yano_y/GTEx_sjout_scality/GTEx_sjouttab_list.txt

bash 2_validation/run.sh ${INPUT} ${OUTPUT_VALIDATION} ${VCF_37} ${PROCESSES} ${MODE} ${CHAIN} ${SJOUT_TAB}

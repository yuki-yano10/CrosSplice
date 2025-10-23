#!/bin/bash
#$ -S /usr/bin/bash
set -euxo pipefail


1) Make a list of all SJ.out.tab file paths (sjouttab_file_path.txt).
2) With this script, generate a list of all samples comtaining sample ID, RUN ID and tissue names. Make sure that you have already downloaded metadata.  

SJOUTTAB_DIR=$WDIR/SJ_out_tab                              
METADATA=$WDIR/refdata/SraRunTable.txt
OUTPUT_FILE=$SJOUTTAB_DIR/sjouttab_list.txt

python3 1_prep/make_gtex_sjouttab_list.py -path_to_sjouttab $SJOUTTAB_DIR/sjouttab_file_path.txt -metadata ${METADATA} -output_file ${OUTPUT_FILE}

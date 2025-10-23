#!/bin/bash
#$ -S /usr/bin/bash
set -euxo pipefail


# This script generates a list of SJ.out.tab files. Make sure that you have already downloaded metadata.  

SJOUTTAB_DIR=$WDIR/SJ_out_tab                              
METADATA=$WDIR/refdata/SraRunTable.txt
OUTPUT_FILE=$SJOUTTAB_DIR/sjouttab_list.txt

python3 1_prep/make_gtex_sjouttab_list.py -path_to_sjouttab $SJOUTTAB_DIR/sjouttab_file.txt -metadata ${METADATA} -output_file ${OUTPUT_FILE}

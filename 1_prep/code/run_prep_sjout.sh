#!/bin/bash
#$ -S /usr/bin/bash
set -euxo pipefail

# 1) download GTEx sj_out_tab

# 2) "Download Metadata:" from https://0-www-ncbi-nlm-nih-gov.brum.beds.ac.uk/Traces/study/?acc=PRJNA75899

# 3) make_gtex_sjouttab_list
#GTEX_SJOUTTAB_DIR=/home/naiida/GTEx/data           # 1)
#METADATA=./data/SraRunTable.txt                    # 2)


METADATA=/home/yano_y/refdata/SraRunTable.txt
OUTPUT_FILE=/home/yano_y/GTEx_sjout_scality/GTEx_sjouttab_list.txt

python3 /home/yano_y/GTEX_validation_project/val_code/make_gtex_sjouttab_list.py -path_to_sjouttab /home/yano_y/GTEx_sjout_scality/GTEx_sjouttab_file.txt -metadata ${METADATA} -output_file ${OUTPUT_FILE}

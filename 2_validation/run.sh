#!/bin/bash
set -euxo pipefail

INPUT=$1
OUTPUT=$2
VCF=$3
PROCESSES=$4

CHAIN=/path/to/hg38ToHg19.over.chain
SJOUTTAB=$WDIR/SJ_out_tab/sjouttab_list.txt

OUTPUT_DIR=$(dirname $OUTPUT)

# liftover and gtexmut
rm -rf ${OUTPUT_DIR}/split ${OUTPUT_DIR}/mutkey_38lift37
mkdir -p ${OUTPUT_DIR}/split ${OUTPUT_DIR}/mutkey_38lift37

python ./code/split_file.py ${INPUT} ${OUTPUT_DIR}/split/ 1000

find ${OUTPUT_DIR}/split/ -type f | xargs -I {} -P ${PROCESSES} \
python ./code/mutkey_38lift37.py {} ${OUTPUT_DIR}/mutkey_38lift37 ${CHAIN} ${VCF} ${SJOUTTAB}

# sj_count
rm -rf ${OUTPUT_DIR}/sj_count
mkdir -p ${OUTPUT_DIR}/sj_count
python ./code/sj_count.py ${OUTPUT_DIR}/mutkey_38lift37/ ${OUTPUT_DIR}/sj_count/ ${PROCESSES}

head -n 1 $(ls ${OUTPUT_DIR}/sj_count/* | head -n 1) > ${OUTPUT}
cat  ${OUTPUT_DIR}/sj_count/* | grep -v ^Chr >> ${OUTPUT}

rm -rf ${OUTPUT_DIR}/split
rm -rf ${OUTPUT_DIR}/mutkey_38lift37
rm -rf ${OUTPUT_DIR}/sj_count

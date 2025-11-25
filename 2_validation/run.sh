#!/bin/bash
set -euxo pipefail

INPUT=$1
OUTPUT=$2
VCF=$3
PROCESSES=$4
MODE=${5:-lift}
CHAIN=$6
SJOUTTAB=$7

OUTPUT_DIR=$(dirname $OUTPUT)

rm -rf ${OUTPUT_DIR}/split ${OUTPUT_DIR}/mutkey_work
mkdir -p ${OUTPUT_DIR}/split ${OUTPUT_DIR}/mutkey_work

# Split the input file into each 1000 rows.
python3 2_validation/split_file.py ${INPUT} ${OUTPUT_DIR}/split/ 1000


# Find splited files in "split" directory and put them in the augument {}.Confirm the existence of each mutation in each sample with mutkey script.
# If your original vcf file is GRCh37 ($MODE=="lift"), the script uses mutkey_38lift37.py. If you do not need liftover ($MODE=="direct"), then mutkey_38direct.py is used. 

if [[ ${MODE} == "lift" ]]; then
	find ${OUTPUT_DIR}/split/ -type f | xargs -I {} -P ${PROCESSES} \
		python3 2_validation/mutkey_38lift37.py {} ${OUTPUT_DIR}/mutkey_work ${CHAIN} ${VCF} ${SJOUTTAB}
else
	find ${OUTPUT_DIR}/split/ -type f | xargs -I {} -P ${PROCESSES} \
		python3 2_validation/mutkey_38direct.py {} ${OUTPUT_DIR}/mutkey_work ${VCF} ${SJOUTTAB}
fi


# Count each hijacked and primary novel SJ in each sample.

rm -rf ${OUTPUT_DIR}/sj_count
mkdir -p ${OUTPUT_DIR}/sj_count
python3 2_validation/sj_count.py ${OUTPUT_DIR}/mutkey_work/ ${OUTPUT_DIR}/sj_count/ ${PROCESSES}


# Merge the output.
head -n 1 $(ls ${OUTPUT_DIR}/sj_count/* | head -n 1) > ${OUTPUT}
cat  ${OUTPUT_DIR}/sj_count/* | grep -v ^Chr >> ${OUTPUT}

rm -rf ${OUTPUT_DIR}/split
rm -rf ${OUTPUT_DIR}/mutkey_work
rm -rf ${OUTPUT_DIR}/sj_count

#!/bin/bash
#$ -S /bin/bash

WDIR=$1
GENCODE=$2
MANE=$3

INPUT_DIR=$WDIR/post_filter
OUTPUT_DIR=$WDIR/output
mkdir -p $OUTPUT_DIR

VAL_INPUT_FORMAT=$OUTPUT_DIR/cross_input.merge.txt
INPUT_FILES=$OUTPUT_DIR/input_files.txt

find ${INPUT_DIR} -type f -name "*.filtered.txt" | sort > ${INPUT_FILES}

python3 1_prep/define_sj.py ${INPUT_FILES} ${VAL_INPUT_FORMAT} ${GENCODE} ${MANE}

#!/bin/bash
set -euxo pipefail

WDIR=$1
BIND_DIR=$2
VEP_IMAGE=$3
DIR_CACHE=$4
REF=$5
GNOMAD=$6
SPLICEAI_SNV=$7
SPLICEAI_INDEL=$8


CHR_LIST="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y"

mkdir -p $WDIR/post_vep

for i in $CHR_LIST; do
    INPUT_VCF=$WDIR/prepared/input.${i}.added.sorted.vcf.gz  #input file should be the output file of proc_vcf.sh script.
    # when liftover was done in the prior step, the input file name shoud be "input.${i}.lift38.sorted.vcf.gz. 
    OUTPUT="$WDIR/post_vep/input.${i}.rare-variant.vep.vcf.gz"

    1_prep/singularity_vep_annot_germline.sh ${BIND_DIR} ${VEP_IMAGE} ${INPUT_VCF} ${OUTPUT} ${DIR_CACHE} ${REF} ${GNOMAD} ${SPLICEAI_SNV} ${SPLICEAI_INDEL}  

done

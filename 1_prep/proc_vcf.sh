#!/bin/bash -x
#$ -S /bin/bash
set -euxo pipefail

CHR_LIST="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 X Y" 

WDIR="$1"
INPUT_VCF38="$2"

VCF_STEM=$(basename "$INPUT_VCF38" .vcf.gz)
VCF_DIR=$WDIR/vcf
POST_DIR=$WDIR/prepared

mkdir -p ${VCF_DIR}
mkdir -p ${POST_DIR}


for i in ${CHR_LIST}; do
    CHR_NUM=$i
    CHR_VCF38_PRE=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.vcf
    CHR_VCF38_UNSORT=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.added.vcf
    
    # separate into chr and bgzip.
    bcftools-1.18/bcftools filter ${INPUT_VCF38} -r ${CHR_NUM} > ${CHR_VCF38_PRE}
    bgzip  -f -c ${CHR_VCF38_PRE} > ${CHR_VCF38_PRE}.gz

    # add "chr" to the number of chromosome.
    1_prep/add_chr.py -vcf ${CHR_VCF38_PRE}.gz -output  

    # sort the data 
    bcftools-1.18/bcftools sort ${CHR_VCF38_UNSORT}.gz > ${CHR_VCF38_SORT}

    # bgzip
    bgzip -f -c ${CHR_VCF38} > ${CHR_VCF38}.gz
    tabix -p vcf ${CHR_VCF38}.gz



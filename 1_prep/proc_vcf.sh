#!/bin/bash -x
#$ -S /bin/bash
set -euxo pipefail

CHR_LIST="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y" 

WDIR="$1"
INPUT_VCF38="$2"

VCF_STEM=$(basename "$INPUT_VCF38" .vcf.gz)
VCF_DIR=$WDIR/vcf
POST_DIR=$WDIR/prepared

mkdir -p ${VCF_DIR}
mkdir -p ${POST_DIR}


for i in ${CHR_LIST}; do
    CHR_NUM=${i}
    CHR_VCF38_PRE=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.vcf.gz
    CHR_VCF38_UNSORT=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.added.vcf
    CHR_VCF38_SORT=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.added.sorted.vcf.gz
    CHR_VCF38=${POST_DIR}/${VCF_STEM}.${CHR_NUM}.added.sorted.vcf.gz
    
    # separate into chr and bgzip.
    bcftools view -r ${CHR_NUM} -O z -o ${CHR_VCF38_PRE} ${INPUT_VCF38}

    # add "chr" prefix.
    1_prep/add_chr.py -vcf ${CHR_VCF38_PRE} -output ${CHR_VCF38_UNSORT}

    # sort and index the data
    bcftools sort ${CHR_VCF38_UNSORT} -O z -o ${CHR_VCF38}
    tabix -p vcf ${CHR_VCF38}

done

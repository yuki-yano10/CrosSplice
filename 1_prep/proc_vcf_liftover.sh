#!/bin/bash -x
#$ -S /bin/bash
set -euxo pipefail

CHR_LIST=$1
WDIR=$2
INPUT_VCF37=$3
CHAIN=$4

VCF_STEM=$(basename "$INPUT_VCF37" .vcf.gz)
VCF_DIR=$WDIR/vcf
POST_DIR=$WDIR/prepared

mkdir -p ${VCF_DIR}
mkdir -p ${POST_DIR}


for i in ${CHR_LIST}; do
    CHR_NUM=${i}
    CHR_VCF37_PRE=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.vcf.gz
    CHR_VCF38_POST=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.lift38.vcf
    CHR_VCF38_UNSORT=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.lift38.unsorted.vcf
    CHR_VCF38=${POST_DIR}/${VCF_STEM}.${CHR_NUM}.lift38.sorted.vcf.gz

    # separate into chr.
    bcftools view -r ${CHR_NUM} -O z -o ${CHR_VCF37_PRE} ${INPUT_VCF37} 
    
    # liftOver
    python3 1_prep/lift37to38_for_vep.py -vcf ${CHR_VCF37_PRE} -output ${CHR_VCF38_POST} -chain ${CHAIN} -target chr${CHR_NUM}

    # tidy the data
    python3 1_prep/tidy_chr.py -input_file ${CHR_VCF38_POST} -output_file ${CHR_VCF38_UNSORT} -target chr${CHR_NUM}

    # sort and index the data 
    bcftools sort ${CHR_VCF38_UNSORT} -O z -o ${CHR_VCF38}
    tabix -p vcf ${CHR_VCF38}

done

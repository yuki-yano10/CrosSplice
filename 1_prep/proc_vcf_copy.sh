#!/bin/bash -x
#$ -S /bin/bash
set -euxo pipefail

CHR_LIST=$1
WDIR=$2
INPUT_VCF=$3
CHR_PRE="${4:?set True if input has `chr` prefix, False otherwise}"

VCF_STEM=$(basename "$INPUT_VCF38" .vcf.gz)
VCF_DIR=$WDIR/vcf
POST_DIR=$WDIR/prepared

mkdir -p ${VCF_DIR}
mkdir -p ${POST_DIR}

if [[ "${CHR_PRE}" == "True" ]]; then
       IN_PREFIX="chr"
else
       IN_PREFIX=""
fi


for i in ${CHR_LIST}; do
    CHR_NUM=${i}
    REGION="${IN_PREFIX}${CHR_NUM}"
    CHR_VCF38_PRE=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.vcf.gz
    CHR_VCF38_UNSORT=${VCF_DIR}/${VCF_STEM}.${CHR_NUM}.added.vcf
    CHR_VCF38=${POST_DIR}/${VCF_STEM}.${CHR_NUM}.prepared.vcf.gz
    
    # separate into chr and bgzip.
    bcftools view -r ${REGION} -Oz -o ${CHR_VCF38_PRE} ${INPUT_VCF38}

    # add "chr" prefix if CHR_PRE is "false".
    if [[ "${CHR_PRE}" == "True" ]]; then
	    zcat ${CHR_VCF38_PRE} > ${CHR_VCF38_UNSORT}
    else
            1_prep/add_chr.py -vcf ${CHR_VCF38_PRE} -output ${CHR_VCF38_UNSORT}

    fi

    # sort and index the data
    bcftools sort ${CHR_VCF38_UNSORT} -O z -o ${CHR_VCF38}
    tabix -p vcf ${CHR_VCF38}

done

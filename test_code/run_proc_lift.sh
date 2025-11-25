#!/bin/bash
#$ -S /bin/bash
set -eup pipefail

module use /usr/local/package/modulefiles
module load samtools

export BCFTOOLS_HOME="/home/yano_y/tool/bcftools-1.18"
export PATH="$BCFTOOLS_HOME:$PATH"

command -v bcftools
bcftools --version

CHR_LIST="22"
WDIR=/home/yano_y/GTEX_validation_project/cros_test
INPUT_VCF37=/home/yano_y/GTEX_validation_project//vcf/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.22.vcf.gz
CHAIN=/home/yano_y/refdata/hg19ToHg38.over.chain
CHR_PRE="False"

1_prep/proc_vcf_liftover.sh ${CHR_LIST} ${WDIR} ${INPUT_VCF37} ${CHAIN} ${CHR_PRE}

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
INPUT_VCF38=/home/yano_y/GTEX_validation_project/prepared/sample.lift38.vcf.gz
CHR_PRE="True"

1_prep/proc_vcf.sh ${CHR_LIST} ${WDIR} ${INPUT_VCF38} ${CHR_PRE}

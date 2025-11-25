#!/bin/bash
#$ -S /bin/bash
set -euxo pipefail

BIND_DIR=$1
VEP_IMAGE=$2
WDIR=$3
DIR_CACHE=$4
REFERENCE=$5
GNOMAD=$6
SPLICEAI_SNV=$7
SPLICEAI_INDEL=$8

INPUT_DIR="${WDIR}/prepared"
echo ${INPUT_DIR}
INPUT_FILES="${INPUT_DIR}/input_files.txt"
OUTPUT_DIR="${WDIR}/post_vep"

mkdir -p ${OUTPUT_DIR}

find ${INPUT_DIR} -type f -name "*.prepared.vcf.gz" | sort > ${INPUT_FILES}

while read -r INPUT_VCF; do
	VCF_STEM=$(basename "$INPUT_VCF" .vcf.gz)
	OUTPUT=${OUTPUT_DIR}/${VCF_STEM}.vep.vcf
	echo "Processing: ${INPUT_VCF}"

        apptainer exec \
	    --bind ${BIND_DIR} \
	    -e ${VEP_IMAGE} \
	    1_prep/shell_vep_annot_germline.sh \
	    ${INPUT_VCF} \
	    ${OUTPUT} \
	    ${DIR_CACHE} \
	    ${REFERENCE} \
	    ${GNOMAD} \
	    ${SPLICEAI_SNV} \
	    ${SPLICEAI_INDEL}

done < ${INPUT_FILES}

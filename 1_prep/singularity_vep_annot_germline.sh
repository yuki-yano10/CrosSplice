#!/bin/bash
#$ -S /bin/bash
set -euxo pipefail

BIND_DIR=$1
VEP_IMAGE=$2
INPUT_VCF=$3
OUTPUT=$4
DIR_CACHE=$5
REFERENCE=$6
GNOMAD=$7
SPLICEAI_SNV=$8
SPLICEAI_INDEL=$9



singularity exec \
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

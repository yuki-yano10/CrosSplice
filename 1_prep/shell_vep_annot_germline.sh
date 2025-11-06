#!/bin/bash

set -x
set -o errexit

INPUT_VCF=$1
OUTPUT_VCF=$2
DIR_CACHE=$3
REFERENCE=$4
GNOMAD=$5
SPLICEAI_SNV=$6
SPLICEAI_INDEL=$7



/opt/vep/src/ensembl-vep/vep \
	-i ${INPUT_VCF} \
	-o ${OUTPUT_VCF} \
	--format vcf \
	--dir_cache ${DIR_CACHE} \
	--dir_plugins ${DIR_CACHE}/Plugins \
	--force_overwrite --vcf --verbose --cache --offline --minimal --var_synonyms --merged --hgvs --hgvsg --no_escape --mane \
	--assembly GRCh38 \
	--fasta ${REFERENCE} \
	--custom ${GNOMAD},gnomADg,vcf,exact,0,AF,AF_eas \
	--plugin SpliceAI,snv=${SPLICEAI_SNV},indel=${SPLICEAI_INDEL}

bgzip -f ${OUTPUT_VCF}
tabix -p vcf ${OUTPUT_VCF}.gz

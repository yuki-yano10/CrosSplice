#!/bin/bash

set -x
set -o errexit
set -o nounset

INPUT_VCF=$1
OUTPUT_VCF=$2
DIR_CACHE=$3
REFERENCE=$4
GNOMAD=$5
CLINVAR=$6
LOFTEE_PATH=$7
LOFTEE_BW=$8
LOFTEE_HA=$9
LOFTEE_SQL=${10}
SPLICEAI_SNV=${11}
SPLICEAI_INDEL=${12}
CADD_SNV=${13}
CADD_INDEL=${14}
TOMMO=${15}
CANCER_GENE_CENSUS=${16}
PCAWG_MUT=${17}
PAN_CAN_ATLAS_MUT=${18}
SAVNET_TCGA=${19}
SAVNET_PCAWG_ICGC=${20}
SAVNET_PCAWG_TCGA=${21}
IRAVDB=${22}
GENIE_MUT=${23}
JUNCMUT=${24}

export PERL5LIB=${PERL5LIB}:${LOFTEE_PATH}

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
	--custom ${CLINVAR},ClinVar,vcf,exact,0,CLNSIG,CLNREVSTAT,CLNDN \
	--custom ${TOMMO},ToMMo,vcf,exact,0,AN,AC,AF \
	--custom ${CANCER_GENE_CENSUS},Cancer_Gene_Census,bed,overlap \
	--custom ${GENIE_MUT},GENIE_Mut,vcf,exact,0,sample_count \
	--custom ${PCAWG_MUT},PCAWG_Mut,vcf,exact,0,donor_count \
	--custom ${PAN_CAN_ATLAS_MUT},PanCanAtlas_Mut,vcf,exact,0,participant_count \
	--custom ${SAVNET_TCGA},SAVNet,vcf,exact,0,cancer_type \
	--custom ${SAVNET_PCAWG_ICGC},SAVNet_PCAWG_ICGC,vcf,exact,0,cancer_type \
	--custom ${SAVNET_PCAWG_TCGA},SAVNet_PCAWG_TCGA,vcf,exact,0,cancer_type \
	--custom ${IRAVDB},IRAVDB,vcf,exact,0,tier \
	--custom ${JUNCMUT},juncmut,vcf,exact,0,sample_count \
	--plugin SpliceAI,snv=${SPLICEAI_SNV},indel=${SPLICEAI_INDEL} \
	--plugin LoF,loftee_path:${LOFTEE_PATH},gerp_bigwig:${LOFTEE_BW},human_ancestor_fa:${LOFTEE_HA},conservation_file:${LOFTEE_SQL} \
	--plugin CADD,${CADD_SNV},${CADD_INDEL}

bgzip -f ${OUTPUT_VCF}
tabix -p vcf ${OUTPUT_VCF}.gz

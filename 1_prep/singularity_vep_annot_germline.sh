#!/bin/bash
#$ -S /bin/bash
set -euxo pipefail

INPUT_VCF="$WDIR/prepared/input.${CHR_NUM}.lift38.vcf.gz"
OUTPUT_VCF="$WDIR/post_vep/input.${CHR_NUM}.lift38_rare-variant.vep.vcf.gz"
DIR_CACHE="/path/to/database/vep_data"
REFERENCE="/path/to/database/Homo_sapiens_assembly38.fasta"
GNOMAD="/path/to/database/gnomAD_3.1.2/gnomad.genomes.v3.1.2.sites.merged.light.vcf.bgz"
SPLICEAI_SNV="/path/to/spliceai_scores.raw.snv.hg38.vcf.gz"
SPLICEAI_INDEL="/path/to/database/spliceai_scores.raw.indel.hg38.vcf.gz"


VEP_IMAGE="$IMAGE_DIR/ensemble-vep.sif"
BIND_DIR="/path/to/data_directory"

singularity exec \
	--bind /path/to/data_directory \
	-e ${IMAGE_DIR}/ensembl-vep-20220216.simg \ 
	./code/shell_vep_annot_germline.sh \
	$INPUT_VCF \
	$OUTPUT_VCF \
	$DIR_CACHE \
	$REFERENCE \
	$GNOMAD \
	$CLINVAR \
	$LOFTEE_PATH \
	$LOFTEE_BW \
	$LOFTEE_HA \
	$LOFTEE_SQL \
	$SPLICEAI_SNV \
	$SPLICEAI_INDEL \
	$CADD_SNV \
	$CADD_INDEL \
	$TOMMO \
	$CANCER_GENE_CENSUS \
	$PCAWG_MUT \
	$PAN_CAN_ATLAS_MUT \
	$SAVNET_TCGA \
	$SAVNET_PCAWG_ICGC \
	$SAVNET_PCAWG_TCGA \
	$IRAVDB \
	$GENIE_MUT \
	$JUNCMUT

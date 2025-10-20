#!/bin/bash

###
# Requirements:
# - Prepare required datasest yourself (paths must be entitled).
# - Minimal: SpliceAI (SNV/INDEL), gnomAD (sites), VEP cache & GRCh38 FASTA.
###

#---- User-configurable ----
: "${WDIR:?Set WDIR (project root)}"
: "${CHR_NUM:?Set CHR_NUM (e.g., 1...22,X,Y)}"
: "${IMAGE_DIR:?Set IMAGE_DIR (dir containing VEP image)}"

INPUT_VCF="$WDIR/prepared/input.${CHR_NUM}.lift38.vcf.gz"
OUTPUT_VCF="$WDIR/post_vep/input.${CHR_NUM}.lift38_rare-variant.vep.vcf.gz"
DIR_CACHE="/path/to/database/vep_data"
REFERENCE="/path/to/database/Homo_sapiens_assembly38.fasta"
GNOMAD="/path/to/database/gnomAD_3.1.2/gnomad.genomes.v3.1.2.sites.merged.light.vcf.bgz"
CLINVAR="/path/to/database/clinvar.vcg.gz"
LOFTEE_PATH=/path/to.loftee
LOFTEE_BW="/path/to/loftee/data/gerp_conservation_scores.homo_sapiens.GRCh38.bw"
LOFTEE_HA="/path/to/loftee/data/human_ancestor.fa.gz"
LOFTEE_SQL="/path/to/loftee/data/loftee.sqtl"
SPLICEAI_SNV="/path/to/spliceai_scores.raw.snv.hg38.vcf.gz"
SPLICEAI_INDEL="/path/to/database/spliceai_scores.raw.indel.hg38.vcf.gz"
CADD_SNV="/path/to/databse/whole_genome_SNVs.tsv.gz"
CADD_INDEL="/path/to/database/gnomad.genomes.r3.0.indel.tsv.gz"
TOMMO="/path/to/database/tommo-38kjpn-20220630-20220929-GRCh38-af-merged.vcf.gz"
CANCER_GENE_CENSUS="/path/to/database/cancer_gene_census_20210409.bed.gz"
PCAWG_MUT="/path/to/final_consensus_passonly.snv_mnv_indel.icgc.public_norm_merged_sorted_grch38.vcf.gz"
PAN_CAN_ATLAS_MUT="/path/to/database/PanCanAtlas_v0.2.8/mc3.v0.2.8.PUBLIC_norm_merged_sorted_grch38.vcf.gz"
SAVNET_TCGA="/path/to/database/TCGA.savnet.with_rescued.result_sorted_norm_grch38.vcf.gz"
SAVNET_PCAWG_ICGC="/path/to/database/sav.icgc_sorted_norm_grch38.vcf.gz"
SAVNET_PCAWG_TCGA="/path/to/database/sav.tcga_sorted_norm_grch38.vcf.gz"
IRAVDB="/path/to/database/iravdb.ver1.0.all.variant_sorted_norm.vcf.gz"
GENIE_MUT="/path/to/database/data_mutations_extended_norm_merged_sorted_grch38.vcf.gz"
JUNCMUT="/path/to/database/TCGASRA_juncmut.filt.sjclass.merge.aggbymut.clin_info.alu.deepi_sorted_norm.vcf.gz"

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

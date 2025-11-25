#!/bin/bash
#$ -S /bin/bash
set -euo pipefail

module use /usr/local/package/modulefiles
module load samtools
module load apptainer 

export BCFTOOLS_HOME="/home/yano_y/tool/bcftools-1.18"
export PATH="$BCFTOOLS_HOME:$PATH"

command -v bcftools
bcftools --version


WDIR="/home/yano_y/GTEX_validation_project/cros_test"
DATA_DIR="/home/yano_y/share_XBLdzEZC/database"
BIND_DIR="${DATA_DIR},/home/yano_y/GTEX_validation_project/cros_test,/home/yano_y/GTEX_validation_project/CrosSplice_code/1_prep"

VEP_IMAGE="/home/yano_y/share_XBLdzEZC/tools/gcatcontainer/ensembl-vep-20220216.simg"
DIR_CACHE="${DATA_DIR}/ensembl-vep/vep_105/vep_data"
REF="${DATA_DIR}/reference/hg38/v0/Homo_sapiens_assembly38.fasta"
GNOMAD="${DATA_DIR}/ensembl-vep/database/gnomAD_3.1.2/gnomad.genomes.v3.1.2.sites.merged.light.vcf.bgz"
SPLICEAI_SNV="${DATA_DIR}/ensembl-vep/database/SpliceAI/spliceai_scores.raw.snv.hg38.vcf.gz"
SPLICEAI_INDEL="${DATA_DIR}/ensembl-vep/database/SpliceAI/spliceai_scores.raw.indel.hg38.vcf.gz"

1_prep/singularity_vep_annot_germline.sh "${BIND_DIR}" "${VEP_IMAGE}" "${WDIR}" "${DIR_CACHE}" "${REF}" "${GNOMAD}" "${SPLICEAI_SNV}" "${SPLICEAI_INDEL}"

# When a variable contains commas inside, make sure to enclose it in double quotes. 

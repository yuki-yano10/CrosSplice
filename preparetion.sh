#!/bin/bash
# =============================================================================
# CrosSplice — database / reference setup.
#
# Downloads and prepares the references that can be fetched automatically, and
# prints instructions for the ones that require authentication or a user choice
# (SpliceAI plugin files and the gnomAD sites VCF).
#
# Usage:
#   bash preparetion.sh [DB_DIR]      # DB_DIR defaults to ./database
#
# After it finishes, set the printed paths in config.yaml.
# Requires: wget, tar, bgzip, tabix, python3, and (for VEP) the container tools.
# =============================================================================
set -euo pipefail

DB_DIR="${1:-$PWD/database}"
REPO_DIR="/path/to/repository"


# run this from the CrosSplice repository root
mkdir -p "${DB_DIR}"
echo "Database directory: ${DB_DIR}"

# --- 1. VEP v105 cache -------------------------------------------------------
echo "== [1/6] VEP v105 cache =="
mkdir -p "${DB_DIR}/vep_105"
if [ ! -e "${DB_DIR}/vep_105/homo_sapiens" ]; then
    wget -c https://ftp.ensembl.org/pub/release-105/variation/vep/homo_sapiens_vep_105_GRCh38.tar.gz \
        -O "${DB_DIR}/vep_105/homo_sapiens_vep_105_GRCh38.tar.gz"
    tar -zxvf "${DB_DIR}/vep_105/homo_sapiens_vep_105_GRCh38.tar.gz" -C "${DB_DIR}/vep_105/"
fi

# --- 2. VEP Singularity image (from the CrosSplice release) ------------------
echo "== [2/6] VEP Singularity image =="
if [ ! -e "${DB_DIR}/ensembl-vep-20220216.simg" ]; then
	wget -c https://github.com/yuki-yano10/CrosSplice/releases/download/vep_image/ensembl-vep-20220216.simg \
        -O "${DB_DIR}/ensembl-vep-20220216.simg"
fi

# --- 3. Reference FASTA (GRCh38) --------------------------------------------
# The Broad public reference bucket. (gs://gcp-public-data--broad-references;
# the .fai index is available alongside the FASTA.)

echo "== [3/6] Reference FASTA =="
REF_BASE="https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0"
if [ ! -e "${DB_DIR}/Homo_sapiens_assembly38.fasta" ]; then
    wget -c "${REF_BASE}/Homo_sapiens_assembly38.fasta" \
        -O "${DB_DIR}/Homo_sapiens_assembly38.fasta"
fi
if [ ! -e "${DB_DIR}/Homo_sapiens_assembly38.fasta.fai" ]; then
    wget -c "${REF_BASE}/Homo_sapiens_assembly38.fasta.fai" \
        -O "${DB_DIR}/Homo_sapiens_assembly38.fasta.fai"
fi

# --- 4. MANE (gff -> json) ---------------------------------------------------
echo "== [4/6] MANE =="
if [ ! -e "${DB_DIR}/MANE.GRCh38.v1.0.ensembl_genomic.json" ]; then
    wget -c https://ftp.ncbi.nlm.nih.gov/refseq/MANE/MANE_human/release_1.0/MANE.GRCh38.v1.0.ensembl_genomic.gff.gz \
        -O "${DB_DIR}/MANE.GRCh38.v1.0.ensembl_genomic.gff.gz"
    python3 "${REPO_DIR}/1_prep/convert_mane_gff_to_json.py" \
        "${DB_DIR}/MANE.GRCh38.v1.0.ensembl_genomic.gff.gz" \
        "${DB_DIR}/MANE.GRCh38.v1.0.ensembl_genomic.json"
fi

# --- 5. GENCODE (-> bgzipped, tabix-indexed BED) -----------------------------
# convert_gencode_to_bed.sh expects wgEncodeGencodeBasicV39.txt.gz in the cwd
# and writes wgEncodeGencodeBasicV39.bed.gz (+ .tbi) there.
echo "== [5/6] GENCODE =="
mkdir -p "${DB_DIR}/gencode"
if [ ! -e "${DB_DIR}/gencode/wgEncodeGencodeBasicV39.bed.gz" ]; then
    wget -c https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeBasicV39.txt.gz \
        -O "${DB_DIR}/gencode/wgEncodeGencodeBasicV39.txt.gz"
    ( cd "${DB_DIR}/gencode" && bash "${REPO_DIR}/1_prep/convert_gencode_to_bed.sh" )
fi

# --- 6. liftOver chains (only needed when mode=lift, i.e. GRCh37 input) -------
echo "== [6/6] liftOver chains (optional; for GRCh37 input) =="
if [ ! -e "${DB_DIR}/hg19ToHg38.over.chain" ]; then
    wget -c https://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz \
        -O "${DB_DIR}/hg19ToHg38.over.chain.gz"
    gunzip -kf "${DB_DIR}/hg19ToHg38.over.chain.gz"
fi
if [ ! -e "${DB_DIR}/hg38ToHg19.over.chain" ]; then
    wget -c https://hgdownload.soe.ucsc.edu/goldenPath/hg38/liftOver/hg38ToHg19.over.chain.gz \
        -O "${DB_DIR}/hg38ToHg19.over.chain.gz"
    gunzip -kf "${DB_DIR}/hg38ToHg19.over.chain.gz"
fi

# --- Manual steps ------------------------------------------------------------
cat <<EOF

=============================================================================
Automatic downloads finished. The following must be prepared MANUALLY, then
their paths set in config.yaml:

  * SpliceAI plugin files (require an Illumina BaseSpace account):
      https://basespace.illumina.com/s/otSPW8hnhaZR
      Download raw_hg38_snv and raw_hg38_indel, then index them with tabix.
        -> spliceai_snv / spliceai_indel

  * gnomAD sites VCF (choose your release from gnomAD Downloads):
      https://gnomad.broadinstitute.org/downloads
      In the study, per-chromosome VCFs were merged and per-sample genotypes
      removed to reduce size; index the result with tabix.
        -> gnomad

Suggested config.yaml values (from this run):
  vep_cache:     ${DB_DIR}/vep_105          # dir that contains homo_sapiens/ (and Plugins/)
  vep_image:     ${DB_DIR}/ensembl-vep-20220216.simg
  reference:     ${DB_DIR}/Homo_sapiens_assembly38.fasta
  mane:          ${DB_DIR}/MANE.GRCh38.v1.0.ensembl_genomic.json
  gencode:       ${DB_DIR}/gencode/wgEncodeGencodeBasicV39.bed.gz
  chain_37to38:  ${DB_DIR}/hg19ToHg38.over.chain
  chain_38to37:  ${DB_DIR}/hg38ToHg19.over.chain
=============================================================================
EOF

#!/bin/bash
# Manual p-value (+ optional figure) step. Wraps the R p-value script and the
# gather script; used by the Snakemake `pvalue`/`gather` rules' underlying tools.
#
# Usage:
#   bash 3_plot/plot_figure.sh INPUT PLOT_DIR [DO_PLOT]
# DO_PLOT=TRUE also writes a per-variant PDF under PLOT_DIR/figure
# (Alternative ratio by tissue, carrier vs non-carrier); defaults to FALSE.
set -euo pipefail

INPUT=$1
PLOT_DIR=$2
DO_PLOT=${3:-FALSE}

# calc p-value (+ optional per-variant figures)
mkdir -p ${PLOT_DIR}/tsv
if [ "${DO_PLOT}" = "TRUE" ]; then mkdir -p ${PLOT_DIR}/figure; fi
Rscript ./3_plot/pararell_get_pvalue_spliceai.R ${INPUT} ${PLOT_DIR} ${DO_PLOT}

# combine p-values
mkdir -p ${PLOT_DIR}/combined
python ./3_plot/gather_combined_p.py ${PLOT_DIR}/tsv/ ${PLOT_DIR}/combined/crossplice_validation_combined_p.tsv

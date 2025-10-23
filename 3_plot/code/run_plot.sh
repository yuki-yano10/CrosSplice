#!/bin/bash
#$ -S /usr/bin/bash

WDIR=/path/to/my/project
INPUT=$WDIR/output/input.validation.txt
VCF=/path/to/vcf/input.vcf.gz
PROCESSES=4
PLOT_DIR=$WDIR/figure_directory
        
mkdir -p ${PLOT_DIR}/tsv
qsub -l lmem,s_vmem=170G -pe def_slot 4 -sync y ./code/plot_figure.sh ${INPUT} ${PLOT_DIR} TRUE

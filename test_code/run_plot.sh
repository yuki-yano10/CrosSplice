#!/bin/bash
#$ -S /usr/bin/bash

WDIR=/home/yano_y/GTEX_validation_project/cros_test
INPUT=$WDIR/output/cross.validation2.txt
VCF=/home/yano_y/phg000830.v1.GTEx_WGS.genotype-calls-vcf.c1/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.vcf.gz
PROCESSES=4
PLOT_DIR=$WDIR/figure_directory
PLOT_CODE="TRUE"  # or "FALSE"

qsub -cwd -l lmem,s_vmem=60G -pe def_slot 4 -sync y ./3_plot/plot_figure.sh ${INPUT} ${PLOT_DIR} ${PLOT_CODE}

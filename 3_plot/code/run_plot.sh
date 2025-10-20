#!/bin/bash
#$ -S /usr/bin/bash

INPUT=/home/yano_y/GTEX_validation_project/output_no_gnomad/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_sjclass_no_af_filtering.validation.txt
VCF=/home/yano_y/phg000830.v1.GTEx_WGS.genotype-calls-vcf.c1/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.vcf.gz
PROCESSES=4
PLOT_DIR=/home/yano_y/GTEX_validation_project/output_no_gnomad/figure_directory
        
mkdir -p ${PLOT_DIR}/tsv
qsub -l lmem,s_vmem=170G -pe def_slot 4 -sync y /home/yano_y/GTEX_validation_project/plot_code_virtual/plot_figure_3.sh ${INPUT} ${PLOT_DIR} FALSE

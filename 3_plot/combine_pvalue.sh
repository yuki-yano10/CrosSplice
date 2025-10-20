#!/bin/bash
#$ -S /usr/bin/bash


PLOT_DIR=/home/yano_y/GTEX_validation_project/output_Virtual
INPUT=/home/yano_y/GTEX_validation_project/output_Virtual/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.virtual_validation.txt 

# calc p-value
# 最後のオプションはプロット出力フラグ
#mkdir -p ${PLOT_DIR}/tsv 
#/usr/local/package/r/4.3.2/bin/Rscript /home/yano_y/GTEX_validation_project/plot_code_virtual/get_pvalue_spliceai.R ${INPUT} ${PLOT_DIR} FALSE

# combine
rm -rf ${PLOT_DIR}/combined
mkdir -p ${PLOT_DIR}/combined
python /home/yano_y/GTEX_validation_project/plot_code_virtual/gather_combined_p.py ${PLOT_DIR}/tsv/ ${PLOT_DIR}/combined/gtex_validation_combined_p.tsv

# plot (各プロジェクトで用意したスクリプトを使用)
#Rscript /path/to/plot.R ${PLOT_DIR}/combined/gtex_validation_combined_p.tsv ${PLOT_DIR}/combined/plot_gtex_validation_combined.pdf

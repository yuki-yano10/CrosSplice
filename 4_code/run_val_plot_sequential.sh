#!/bin/bash
#$ -S /usr/bin/bash


INPUT=/home/yano_y/GTEX_validation_project/output_Scal/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.merge.txt
VCF=/home/yano_y/phg000830.v1.GTEx_WGS.genotype-calls-vcf.c1/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.vcf.gz
PROCESSES=4                    

for i in $(seq 0 0)
do
	mkdir -p /home/yano_y/GTEX_validation_project/output_Virtual_tissue/out_$i
	OUTPUT_VALIDATION=/home/yano_y/GTEX_validation_project/output_Virtual_tissue/out_$i/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.virtual_validation.$i.txt
	SJOUTTAB=/home/yano_y/GTEX_validation_project/tissue_virtual_path/tissue_virtual_transcriptome_list_$i.txt
	#1 Validation
	qsub -l lmem,s_vmem=40G -sync y /home/yano_y/GTEX_validation_project/virtual_val_code/run.sh ${INPUT} ${OUTPUT_VALIDATION} ${VCF} ${SJOUTTAB} ${PROCESSES}
	#2 Calculate p-value and combine
	PLOT_DIR=/home/yano_y/GTEX_validation_project/output_Virtual_tissue/out_$i
	mkdir -p ${PLOT_DIR}/tsv
        qsub -l lmem,s_vmem=40G -pe def_slot 4 -sync y /home/yano_y/GTEX_validation_project/plot_code_virtual/plot_figure_2.sh ${OUTPUT_VALIDATION} ${PLOT_DIR} FALSE $i
	rm ${OUTPUT_VALIDATION}
done

#!/bin/bash
#$ -S /usr/bin/bash
#$ -pe def_slot 4


INPUT=/home/yano_y/GTEX_validation_project/output_Scal/sjclass_unannotated_merge.txt
# Input file is "merge.validation.txt" ex) GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.merge.validation.txt

OUTPUT_VALIDATION=/home/yano_y/GTEX_validation_project/output_Scal/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_sjclass_unannotated.validation.txt
# Output file is "validation.txt" ex) GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.005.validation.txt

VCF=/home/yano_y/phg000830.v1.GTEx_WGS.genotype-calls-vcf.c1/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.vcf.gz
PROCESSES=4                    

bash /home/yano_y/GTEX_validation_project/val_code/run.sh ${INPUT} ${OUTPUT_VALIDATION} ${VCF} ${PROCESSES}

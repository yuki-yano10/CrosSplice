#!/bin/bash
#$ -S /usr/bin/bash
#$ -pe def_slot 4
set -xeuo pipefail

WDIR=/home/yano_y/GTEX_validation_project/cros_test
INPUT=$WDIR/output/cross_input.merge.txt
OUTPUT_VALIDATION=$WDIR/output/cross.validation2.txt
VCF_37=/home/yano_y/phg000830.v1.GTEx_WGS.genotype-calls-vcf.c1/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.vcf.gz  #put the original vcf file befored devided
PROCESSES=4
MODE="lift"  #If your original vcf file is GRCh37, set "lift", then the script uses mutkey_38lift37.py. If you do not need liftover, set "direct", then mutkey_38direct.py is used. 
CHAIN=/home/yano_y/refdata/hg38ToHg19.over.chain  #Put "NONE" if you do not need liftover.
SJOUT_TAB=/home/yano_y/GTEx_sjout_scality/GTEx_sjouttab_list.txt

bash 2_validation/run.sh ${INPUT} ${OUTPUT_VALIDATION} ${VCF_37} ${PROCESSES} ${MODE} ${CHAIN} ${SJOUT_TAB}

#!/bin/bash
#$ -S /usr/bin/bash
#$ -pe def_slot 4


INPUT=$WDIR/output/input.merge.txt
OUTPUT_VALIDATION=$WDIR/output/input.validation.txt
VCF=/path/to/vcf/input.vcf.gz
PROCESSES=4                    

bash ./code/run.sh ${INPUT} ${OUTPUT_VALIDATION} ${VCF} ${PROCESSES}

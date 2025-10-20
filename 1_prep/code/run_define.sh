#!/bin/bash
#$ -S /bin/bash


WDIR=/path/to/my/project
INPUT_DIR=$WDIR/post_filter
INPUT_FILES=$INPUT_DIR/input_files.txt
VAL_INPUT_FORMAT=$WDIR/output/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.merge.txt

GENCODE=/path/to/wgEncodeGencodeBasicV39.bed.gz
MANE=/path/to/MANE.GRCh38.v1.0.ensembl_genomic.gff.transcript_tag.json
VCF=/path/to/phg000830.v1.GTEx_WGS.genotype-calls-vcf.c1/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.vcf.gz


# define_sj
find ${INPUT_DIR} -type f -name "*.spliceaiG01.txt" | sort > ${INPUT_FILES}
python3 code/define_sj.py ${INPUT_FILES} ${VAL_INPUT_FORMAT} ${GENCODE} ${MANE}

#!/bin/bash
#$ -S /bin/bash


WDIR=/path/to/my/project
INPUT_FILE=$WDIR/post_filter/input.all.gnomad001.spliceaiG01.txt
VAL_INPUT_FORMAT=$WDIR/output/input.merge.txt

GENCODE=/path/to/wgEncodeGencodeBasicV39.bed.gz
MANE=/path/to/MANE.GRCh38.v1.0.ensembl_genomic.gff.transcript_tag.json
VCF=/path/to/vcf/input.vcf.gz


python3 1_prep/define_sj.py ${INPUT_FILE} ${VAL_INPUT_FORMAT} ${GENCODE} ${MANE}

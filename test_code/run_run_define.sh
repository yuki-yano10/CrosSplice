#!/bin/bash
#$ -S /bin/bash
set -euo pipefail

WDIR=/home/yano_y/GTEX_validation_project/cros_test
GENCODE=/home/yano_y/refdata/wgEncodeGencodeBasicV39.bed.gz
MANE=/home/yano_y/refdata/MANE/MANE.GRCh38.v1.0.ensembl_genomic.gff.transcript_tag.json

1_prep/run_define.sh ${WDIR} ${GENCODE} ${MANE}

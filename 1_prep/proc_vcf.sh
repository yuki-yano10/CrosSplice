#!/bin/bash -x
#$ -S /bin/bash
#$ -l s_vmem=10G

CHR_LIST="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 X Y" 
CHR_NUM = i from $CHR_LIST
 
WDIR=/path/to/my/project
INPUT_VCF37=/path/to/vcf/input.vcf.gz
CHR_VCF_PRE=$WDIR/vcf/input.${CHR_NUM}.vcf
CHR_VCF=$WDIR/vcf/input.${CHR_NUM}.vcf.gz
CHR_VCF38_unsort=$WDIR/vcf/input.${CHR_NUM}.lift38.unsorted.vcf
CHR_VCF38_unsort2=$WDIR/vcf/input.${CHR_NUM}.lift38.unsorted2.vcf
CHR_VCF38=$WDIR/prepared/input.${CHR_NUM}.lift38.vcf

CHAIN=/path/to/hg19ToHg38.over.chain

# separate into chr.
bcftools-1.18/bcftools filter ${INPUT_VCF37} -r ${CHR_NUM} > ${CHR_VCF_PRE}
bgzip  -f -c ${CHR_VCF_PRE} > ${CHR_VCF}

# liftOver
python3 ./code/lift37to38_for_vep.py -vcf ${CHR_VCF} -output ${CHR_VCF38_unsort} -chain ${CHAIN} -target chr${CHR_NUM}


# tidy the data
python3 ./code/tidy_chr.py -input_file ${CHR_VCF38_unsort} -output_file ${CHR_VCF38_unsort2} -target chr${CHR_NUM}

# sort the data 
bcftools-1.18/bcftools sort ${CHR_VCF38_unsort2} > ${CHR_VCF38}

rm ${CHR_VCF38_unsort}
rm ${CHR_VCF38_unsort2}

# bgzip
bgzip -f -c ${CHR_VCF38} > ${CHR_VCF38}.gz
tabix -p vcf ${CHR_VCF38}.gz



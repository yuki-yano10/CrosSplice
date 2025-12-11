# CrosSplice
## Introduction
**CrosSplice** is a pipeline to identify spilice-site creating variants (SSCVs) from cross-tissue transcriptome data.  
CrosSplice uniquely captures rare and tissue-specific SSCVs beyond the reach of conventional approaches, owing to its distinctive design:
1. **Integration of sQTL approaches and machine learning-based methods**, by pinpointing candidate SSCVs with their associated splicing junctions predicted by SpliceAI, and reinforcing these predictions through statistical association testing.
2. **Leveraging cross-tissue transcriptome data** to aggregate splicing signals across multiple tissues.
<br>
You can apply CrosSplice to your own WGS and corresponding RNA-seq data.

<br>
<br>

## Dependency
### Environment
Prepare an environment where you can use **Singurality/Apptainer**, **VEP** and **qsub**.
Pipeline orchestration and job scheduling were implemented mostly in **Bash** 

### Software  
- bcftools  
- tabix  
- bgzip
- VEP v105
- Singularity/Apptainer
- liftOver (optional; required when input data are in GRCh37)

<br>

Add `/path/to/software` to your PATH.

### Python
Python (>= 3.7)

### R
R (>=4.3.0), ```tidyverse```

<br>


## Preparetion
### 1. VEP v105
- download a cache file for vep v105 and extract it before use.
```
wget https://ftp.ensembl.org/pub/release-105/variation/vep/homo_sapiens_vep_105_GRCh38.tar.gz
tar -zxvf homo_sapiens_vep_105_GRCh38.tar.gz
```
- prepare plugin files for SpliceAI annotation from Illumina basespace (https://basespace.illumina.com/s/otSPW8hnhaZR).
  Download the ```raw_hg38_snv``` and ```raw_hg38_indel``` file, and make sure to index downloaded files using ```tabix```.
- prepare a gnomAD variant file (```sites.vcf.bgz```) for gnomAD annotation from gnomAD Downloads (https://gnomad.broadinstitute.org/downloads).
  In our study, we merged VCF files from all chromosomes and removed per-sample genotype information to reduce file size and improve data access efficiency. Make sure to index the vcf file using ```tabix```.
- prepare a reference FASTA file. In our study, we used ```Homo_sapiens_assembly38.fasta``` downloaded from the DDJB site.
- prepare the Singularity image for vep.
  A pre-built Singularity image is available in this repository's [Release].
  Download as follows:   
  ```bash
  wget https://github.com/yuki-yano10/CrosSplice/releases/download/vep_image/ensembl-vep-20220216.simg 
  ```
  
  
<br>

### 2. MANE file
- download a MANE gff file. 
```
wget https://ftp.ncbi.nlm.nih.gov/refseq/MANE/MANE_human/release_1.0/MANE.GRCh38.v1.0.ensembl_genomic.gff.gz
```   
- Convert the downloaded gff file into json format using 1_prep/convert_mane_gff_to_json.py.

```
python3 1_prep/convert_mane_gff_to_json.py /path/to/MANE.GRCh38.v1.0.ensembl_genomic.gff.gz /path/to/MANE.GRCh38.v1.0.ensembl_genomic.json
```

<br>

### 3. GENCODE file
- download a GENCODE file.
```
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeGeneSymbolV39.txt.gz
```
- Convert the file into bed format and compress, using 1_prep/convert_gencode_to_bed.sh.

<br>


### 4. Prepare the input WGS and corresponding RNA-eq data
- prepare a VCF file containing genotype information obtained from WGS data (e.g., output of GATK HaplotypeCaller), along with the corresponding RNA-seq data.
- perform STAR alignment on RNA-seq data to generate SJ.out.tab files.
- bgzip the SJ.out.tab files.
- prepare metadata that associates each RNA-seq sample with its corresponding WGS sample and tissue name, and create a sample list (```sjouttab_list.txt```) containing tisuse names in the follwoing format:

```
Repository_sample_id    Run     Tissue  Path
GTEX-1117F      SRR8176157      Adipose_Tissue.Adipose-Subcutaneous     /home/yano_y/GTEx_SJ.out/GTEX_Adipose_Tissue.Adipose-Subcutaneous/GRCh38.d1.vd1_Adipose_Tissue.Adipose-Subcutaneous/GCATWorkflow-3.0.2.iravnet/star/GTEX-1117F-0226-SM-5GZZ7/GTEX-1117F-0226-SM-5GZZ7.SJ.out.tab.gz
GTEX-1117F      SRR8176158      Muscle.Muscle-Skeletal  /home/yano_y/GTEx_SJ.out/GTEX_Muscle.Muscle-Skeletal/GRCh38.d1.vd1/GCATWorkflow-3.0.2.iravnet/star/GTEX-1117F-0426-SM-5EGHI/GTEX-1117F-0426-SM-5EGHI.SJ.out.tab.gz
...
```
<br>

### Optional; liftOver (required when input data are in GRCh37) 
- download a chain file for liftover between GRCh37 and GRCh38.
```
wget ftp://hgdownload.cse.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz
```
Make sure to unzip the downloaded chain file.

<br>
<br>

## Pipeline

### 1. Preprocessing of a VCF file.
Preprocess the input VCF file using the following script.

```bash
#!/bin/bash
CHR_LIST="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y"
WDIR=/path/to/my/project
INPUT_VCF38=/path/to/vcf/input.GRCh38.vcf.gz
CHR_PRE="true" # set to "true" if chromosome names in the input VCF contains the "chr" prefix, otherwise "false"

1_prep/proc_vcf.sh "${CHR_LIST}" ${WDIR} ${INPUT_VCF38}
```
<br>

(**Optional**)  
When the input file is aligned to GRCh37 and LiftOver is required, you can use the script below instead.

```bash
#!/bin/bash
CHR_LIST="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y"
WDIR=/path/to/my/project
INPUT_VCF37=/path/to/vcf/input.GRCh37.vcf.gz
CHAIN=/path/to/hg19ToHg38.over.chain
CHR_PRE="True" # set to "true" if chromosome names in the input VCF contains the "chr" prefix, otherwise "false".
Allowed values (case-inseisitive): ```true/false```, 

1_prep/proc_vcf_liftover.sh "${CHR_LIST}" ${WDIR} ${INPUT_VCF37} ${CHAIN} ${CHR_PRE}
```

<br>

### 2. Annotate variants in VCF files using VEP.

Apply VEP to the preprocessed VCF files to annotate variants with information includion SpliceAI scores and gnomAD allele frequencies. When the "BIND_DIR" variable contains commas inside, make sure to enclose it in double quotes.

```bash

WDIR="/path/to/my/project"
BIND_DIR="/path/to/database,/path/to/my/project,1_prep"
VEP_IMAGE="/path/to/ensembl-vep-20220216.simg"
DIR_CACHE="/path/to/database/vep_105/vep_data"
REF="/path/to/database/Homo_sapiens_assembly38.fasta"
GNOMAD="/path/to/database/gnomad.genomes.v3.1.2.sites.merged.light.vcf.bgz"
SPLICEAI_SNV="/path/to/database/spliceai_scores.raw.snv.hg38.vcf.gz"
SPLICEAI_INDEL="/path/to/database/spliceai_scores.raw.indel.hg38.vcf.gz"

1_prep/singularity_vep_annot_germline.sh "${BIND_DIR}" "${VEP_IMAGE}" "${WDIR}" "${DIR_CACHE}" "${REF}" "${GNOMAD}" "${SPLICEAI_SNV}" "${SPLICEAI_INDEL}"  

```
<br>

### 3. Filtering

Filter variants to retain only SNVs with SpliceAI DS_AG or DS_DG ≥ 0.1, and gnomAD AF ≤ 0.01. 

```bash
WDIR=/path/to/my/project

python3 1_prep/vep_filter_spliceai_gnomad.py $WDIR
```

<br>

### 4. Define Hijacked SJ and Primary novel SJ, and Create an input file.

For each retained SNVs (SSCV candidate), **hijacked SJ** and **primary SJ** are difined for each variant.  
Then, create an input file (*.merge.txt) in the following format, using the script below.

<br>

Format

```
1. Chr
2. Position
3. Ref
4. Alt
5. Primary_SJ
6. Hijacked_SJ
7. Gene
8. SpliceAI_score
```
<br>

Script

```
WDIR=/path/to/my/project
GENCODE=/path/to/gencode.bed.gz
MANE=/path/to/mane.json

1_prep/run_define.sh ${WDIR} ${GENCODE} ${MANE}
```
<br>
<br>

## Validation

SJ.out.tab files are parsed to count the number of supporting reads for the hijacked SJ **(#hijacked_SJ)** and primary novel SJ **(#primary_novel_SJ)** in each sample.
For each variant, an **alternative ratio** is calculated as follows.

<br>

***depth = #hijacked_SJ + #primary_novel_SJ***
<br>
***alternative ratio = #primary_novel_SJ / (depth + 1)*** 
<br>
<br>

### Script

When you DO NOT need liftover, set "lift" in "MODE" augment, and give a chain file path (hg38ToHg19).
If the liftover is NEEDED, set "direct" in "MODE" augment and put "NONE" to "CHAIN" augment.
For "VCF" augment, give a path of original vcf file before devided. For "SJOUT_TAB" augment, give a file path for the sjouttab list you made in the previous section. You can adjust the "PROCESSES" number.

An example below is the script when liftover is needed.
```
WDIR=/path/to/my/project
INPUT=$WDIR/output/cross_input.merge.txt
OUTPUT_VALIDATION=$WDIR/output/cross.validation.txt
VCF=/path/to/vcf/input.GRCh37.vcf.gz
PROCESSES=4
MODE="lift"
CHAIN=/path/to/hg38ToHg19.over.chain
SJOUT_TAB=/path/to/sjouttab_list.txt

bash 2_validation/run.sh ${INPUT} ${OUTPUT_VALIDATION} ${VCF} ${PROCESSES} ${MODE} ${CHAIN} ${SJOUT_TAB}
```

<br>
<br>

## Calculate p-values and Plot     

Calculate p-values to measure the difference in the alternative ratio between samples with and without the variant using a one-sided Wilcoxon rank-sum test.  
Lastly, integrate the p-values of each tissue into a single combined p-value using Fisher’s method. 

<br>

### Script

```
WDIR=/path/to/my/project
INPUT=$WDIR/output/cross.validation.txt
VCF=/path/to/vcf.gz
PROCESSES=4
PLOT_DIR=$WDIR/figure_directory

qsub -cwd -l lmem,s_vmem=60G -pe def_slot 4 -sync y 3_plot/plot_figure.sh ${INPUT} ${PLOT_DIR}
```           


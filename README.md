# CrosSplice
This repository contains all scripts for running CrosSplice.
<br>
<br>

## Requirement

1. Download RNA-seq data and perform STAR alignment to generate SJ.out.tab files.
2. Bgzip SJ.out.tab files.
3. Make a SJ.out.tab file list with the following code.
```
bash 1_prep/run_prep_sjout.sh
```
4. Download a VCF file containing genotype information.
5. Download metadata.
```
wget https://0-www-ncbi-nlm-nih-gov.brum.beds.ac.uk/Traces/study/?acc=PRJNA75899
```
6. Download a chain file for liftover between GRCh37 and GRCh38.
```
wget ftp://hgdownload.cse.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz
```
7. Download a MANE file.
```
wget https://ftp.ncbi.nlm.nih.gov/refseq/MANE/MANE_human/release_1.0/MANE.GRCh38.v1.0.ensembl_genomic.gtf.gz
```
<br>
<br>

## Preprocessing, Filtering and Generation of an input file for validation.

1. Preprocessing of VCF file.

```
proc_vcf.sh
      |-- separate into each chr   (bcftools filter)
      |-- liftover                 (lift37to38_for_vep.py)
      |-- tidy the data            (tidy_chr.py)
      |-- sort the data            (bcftools sort)
      |-- bgzip and tabix
```
<br>

2. Annotate variants in the VCF file using VEP.

```
singularity_vep_annot_germline.sh
      |-- shell_vep_annot_germline.sh
```
<br>

3. Filtering

Filter down to only SNVs with SpliceAI DS_AG/DS_DG ≥ 0.1, and gnomAD AF ≤ 0.01. 

```
python vep_filter_spliceai_gnomad.py
```

<br>

4. Define Hijacked SJ and Primary novel SJ, and Create an input file.

From the remaining SNVs, hijacked SJ and primary SJ are difined for each variant (SSCV candidate).  
Then, create an input file in the following format, using the script below.

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
run_define.sh
     |-- define_sj.py
```
<br>
<br>

## Validation

```
run_val.sh
    |-- run.sh
           |-- split_file.py
           |-- mutkey_key sj_count.py

```

## Plot     
                     --------  run_plot.sh  ----  
                                                            plot_figure.sh

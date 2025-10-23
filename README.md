# CrosSplice
This repository contains all scripts for running CrosSplice.

## Requirement

1. Download RNA-seq data and perform STAR alignment to generate SJ.out.tab files.
2. Bgzip the SJ.out. SJ.out.bed.gz file using bgzip.
3. Make a SJ.out.tab file list with the following code.
```
1_prep/run_prep_sjout.sh ---- make_gtex_sjouttab_list.py
```
4. Download a VCF file
5. Download the metadata.
```
wget https://0-www-ncbi-nlm-nih-gov.brum.beds.ac.uk/Traces/study/?acc=PRJNA75899
```
7. Download a chain file for liftover between GRCh37 and GRCh38
8. Download a MANE file.
```
wget https://ftp.ncbi.nlm.nih.gov/refseq/MANE/MANE_human/release_1.0/MANE.GRCh38.v1.0.ensembl_genomic.gtf.gz
```

2) Prepare VCF files, filterand generate an input file.
prep ------ proc_vcf.sh
                                           ------ separate into each chr. (bcftools filter)
                                           ------  liftover  (lift37to38_for_vep.py)                                     
                                           ------  tidy the data (tidy_chr.py)
                                           ------  sort the data (bcftools sort)
                                           ------  bgzip and tabix
    2. VEP  ------- singularity_vep_annot_germline.sh  ------ shell_vep_annot_germline.sh
                          
    3.  Filtering ------ vep_filter_spliceai_gnomad.py 
    4.  Define Hijacked SJ and Primary novel SJ  and make an input file
                                          ---- run_define.sh  ----- define_sj.py


3)   Validation
                      ----------- run_val.sh  ----- run.sh
                                                                 ----------  split_file.py
                                                                 ----------  mutkey_38lift37.py
                                                                 ----------  sj_count.py

4)   Plot     
                     --------  run_plot.sh  ----  
                                                            plot_figure.sh

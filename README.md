# CrosSplice

## Introduction
**CrosSplice** is a pipeline to identify splice-site creating variants (SSCVs) from cross-tissue transcriptome data.
CrosSplice uniquely captures rare and tissue-specific SSCVs beyond the reach of conventional approaches, owing to its distinctive design:
1. **Integration of sQTL approaches and machine learning-based methods**, by pinpointing candidate SSCVs with their associated splicing junctions predicted by SpliceAI, and reinforcing these predictions through statistical association testing.
2. **Leveraging cross-tissue transcriptome data** to aggregate splicing signals across multiple tissues.

You can apply CrosSplice to your own WGS and corresponding RNA-seq data.

This repository wraps the pipeline in a **Snakemake** workflow so it can be run end-to-end with a single command, while the original per-step scripts remain available for manual/advanced use.

<br>

## Intended use and assumptions

CrosSplice is primarily designed to detect **germline** or **constitutional splice-site-creating variants** from **paired WGS and RNA-seq data**. The pipeline assumes that variant carrier status can be defined from DNA sequencing data and compared with RNA-seq junction read support across carrier and non-carrier samples.

One of the key features of CrosSplice is the ability to aggregate RNA-seq evidence across multiple tissues.

In our study (https://www.medrxiv.org/content/10.64898/2025.12.21.25342246v1), we used the GTEx dataset, which includes postmortem multi-tissue transcriptomes, to maximize the benefit of this cross-tissue design. However, CrosSplice does not require postmortem tissue or a large multi-tissue panel, and can be applied to available paired DNA and RNA-seq data from clinically accessible tissues such as blood or skin. When only one or two tissues are available, sensitivity is expected to depend on whether the candidate gene is expressed and whether the variant-associated junction is captured in the sampled tissue; when possible, tissue choice should be guided by candidate-gene expression, disease biology, and sample availability.

Application to somatic or mosaic variants, including cancer-associated mutations, may require additional preprocessing such as somatic variant calling, consideration of variant allele fraction, tumor purity, clonality, and tissue composition. These settings have not yet been systematically benchmarked in the current implementation.

<br>

## Dependency
### Environment
Prepare an environment where you can use **Singularity/Apptainer**, **VEP** and a **Grid Engine (SGE/UGE) cluster** (job submission via `qsub`). Pipeline orchestration is implemented with **Snakemake**.

### Software
- Snakemake (>= 8; tested with 9.x)
- bcftools, tabix, bgzip
- VEP v105
- Singularity/Apptainer
- liftOver (optional; required when input data are in GRCh37)

Add `/path/to/software` to your PATH.

### Python
Python (>= 3.7), `pysam`

### R
R (>= 4.3.0), `tidyverse`, `foreach`, `doParallel`

<br>

## Installation
```bash
git clone https://github.com/yuki-yano10/CrosSplice.git
cd CrosSplice

# install Snakemake (and, for cluster submission, the generic executor plugin)
pip install snakemake snakemake-executor-plugin-cluster-generic
```

<br>

## Preparation

### Automatic setup
Most references can be downloaded and prepared automatically:
```bash
bash preparetion.sh /path/to/database
```
This fetches the VEP v105 cache, the VEP Singularity image, the GRCh38 reference
FASTA, MANE (converted to JSON), GENCODE (converted to a tabix-indexed BED) and
the liftOver chains, then prints the paths to set in `config.yaml`.

Two inputs must be prepared **manually** (they require an account or a user choice):
- **SpliceAI plugin files** from Illumina BaseSpace (https://basespace.illumina.com/s/otSPW8hnhaZR):
  download `raw_hg38_snv` and `raw_hg38_indel` and index them with `tabix`.
- **gnomAD sites VCF** from gnomAD Downloads (https://gnomad.broadinstitute.org/downloads):
  in our study we merged per-chromosome VCFs and removed per-sample genotypes to
  reduce size; index the result with `tabix`.

### Input WGS and RNA-seq data
- Prepare a VCF containing genotypes from WGS (e.g. GATK HaplotypeCaller output).
- Run STAR alignment on the RNA-seq data to generate `SJ.out.tab` files, and `bgzip` and index them using `tabix`.
- Prepare a sample list (`sjouttab_list.txt`) associating each RNA-seq sample with
  its WGS sample and tissue, in the following format:

```
Repository_sample_id    Run     Tissue  Path
GTEX-1117F      SRR8176157      Adipose_Tissue.Adipose-Subcutaneous     /path/to/GTEX-1117F-...SJ.out.tab.gz
GTEX-1117F      SRR8176158      Muscle.Muscle-Skeletal                  /path/to/GTEX-1117F-...SJ.out.tab.gz
...
```

<br>

## Quick start (Snakemake — recommended)

1. Edit `config.yaml`: set `wdir`, `input_vcf`, `mode` (`direct` for GRCh38,
   `lift` for GRCh37), the database paths, and `sjouttab_list`. To also render a
   per-variant figure for each candidate, set `make_plots: true` (off by
   default; the combined p-value does not require the figures).
2. Check the plan with a dry run (run everything from the repository root):
   ```bash
   snakemake -n
   ```
3. Run on your Grid Engine (SGE/UGE) cluster (submits each rule as a qsub job via `profiles/gridengine/`):
   ```bash
   bash run.sh
   ```
   `run.sh` forwards any extra arguments to Snakemake, so you can also do
   `bash run.sh -n` (dry run) or target an intermediate stage:
   - `bash run.sh prep`        -> up to `cross_input.merge.txt`
   - `bash run.sh validation`  -> up to `cross.validation.txt`
   - default                   -> `figure_directory/combined/crossplice_validation_combined_p.tsv`

Adjust `profiles/gridengine/config.yaml` (qsub resource flags, job classes) and
the per-rule `resources` in `config.yaml` to your site. Snakemake resumes
automatically; after an interruption add `--rerun-incomplete`.

### Try it on the bundled test dataset

A tiny, fully synthetic dataset is included to check the installation. It runs
in seconds with the normal entry points (no databases needed):

```bash
tar xzf test/data.tar.gz -C test/
snakemake --configfile test/config.test.yaml -c1 all
```

It should detect the positive variant (PLA2G6, `-log10` combined p ≈ 12.7) and
leave the negative control below the threshold. See `test/README.md` for
details and a step-by-step (non-Snakemake) alternative.

### Workflow overview
```
proc_vcf(per-chr) -> vep_annotate(per-chr) ┐
                                           ├-> filter -> define_sj
                                           ┘                 │
                                              split_input(checkpoint)
                                                             │
                                        mutkey_one(per-split, cluster-parallel)
                                                             │
                                          sj_count -> merge_validation
                                                             │
                                        pvalue(R) -> gather -> combined_p.tsv
```

### Directory structure
```
.
├── README.md
├── Snakefile              # the workflow (all rules)
├── config.yaml            # user configuration (paths, resources)
├── run.sh                 # launcher (snakemake + Grid Engine profile)
├── preparetion.sh         # database / reference setup
├── profiles/
│   └── gridengine/
│       └── config.yaml    # Grid Engine (SGE/UGE) qsub submission profile
├── 1_prep/                # stage 1 scripts (preprocessing, VEP, filter, define SJ)
├── 2_validation/          # stage 2 scripts (split, mutkey, sj_count)
├── 3_plot/                # stage 3 scripts (p-value, gather)
└── test/                  # bundled synthetic test dataset (see test/README.md)
```

<br>

## Running individual steps manually (advanced)

The Snakemake rules simply wrap the scripts below. You can run them by hand for
debugging or to re-run a single stage. All commands are run from the repository
root; `WDIR` is the working directory set as `wdir` in `config.yaml`.

### 1. Preprocess the VCF (per chromosome)
```bash
# GRCh38 input:
1_prep/proc_vcf.sh "1 2 ... X Y" ${WDIR} ${INPUT_VCF38} ${CHR_PRE}
# GRCh37 input (liftover to GRCh38):
1_prep/proc_vcf_liftover.sh "1 2 ... X Y" ${WDIR} ${INPUT_VCF37} ${CHAIN_37to38} ${CHR_PRE}
```

### 2. VEP annotation (SpliceAI + gnomAD)
```bash
1_prep/singularity_vep_annot_germline.sh "${BIND_DIR}" "${VEP_IMAGE}" "${WDIR}" \
    "${DIR_CACHE}" "${REF}" "${GNOMAD}" "${SPLICEAI_SNV}" "${SPLICEAI_INDEL}"
```

### 3. Filter (SpliceAI DS_AG or DS_DG >= 0.1, gnomAD AF <= 0.01)
```bash
python3 1_prep/vep_filter_spliceai_gnomad.py ${WDIR}
```

### 4. Define hijacked / primary novel SJ -> input file
```bash
1_prep/run_define.sh ${WDIR} ${GENCODE} ${MANE}
```

### 5. Validation (count SJ.out.tab reads -> alternative ratio)
```bash
# MODE=direct (GRCh38) or MODE=lift (GRCh37; CHAIN = hg38ToHg19)
bash 2_validation/run.sh ${INPUT} ${OUTPUT_VALIDATION} ${VCF} ${PROCESSES} ${MODE} ${CHAIN} ${SJOUT_TAB}
```
For each variant, `depth = #hijacked_SJ + #primary_novel_SJ` and the
**alternative ratio** = `#primary_novel_SJ / (depth + 1)`.

### 6. Calculate p-values (and, optionally, plot)
```bash
# The third argument is optional: TRUE also writes a per-variant PDF under
# ${PLOT_DIR}/figure (default FALSE, i.e. p-values only).
qsub -cwd -l lmem,s_vmem=60G -pe def_slot 4 -sync y 3_plot/plot_figure.sh ${INPUT} ${PLOT_DIR} FALSE
```
Per-tissue one-sided Wilcoxon rank-sum tests are combined per variant with
Fisher's method into a single combined p-value.

<br>

## Validation output

The validation step outputs a sample-level tab-delimited file. Each row represents one SSCV candidate in one RNA-seq sample/tissue.

| Column | Description |
|---|---|
| `Chr`, `Position`, `Ref`, `Alt` | Genomic coordinate and alleles of the candidate SSCV |
| `Primary_SJ` | CrosSplice-defined primary novel splice junction predicted to be created by the variant |
| `Hijacked_SJ` | Canonical splice junction expected to be displaced by the primary novel SJ |
| `Gene` | Gene symbol |
| `SpliceAI_score` | SpliceAI delta score used for candidate prioritization |
| `MANE` | MANE transcript category |
| `Repository_sample_id`, `Run`, `Tissue` | RNA-seq sample and tissue identifiers |
| `SJ_out_tab_path` | Path to the STAR SJ.out.tab file used for read counting |
| `Primary_read_count` | Number of reads supporting the primary novel SJ |
| `Hijacked_read_count` | Number of reads supporting the hijacked SJ |
| `Depth` | Sum of primary novel SJ and hijacked SJ read counts |
| `Rate` | `Primary_read_count / (Hijacked_read_count + 1)` |
| `Ratio` | `Primary_read_count / (Depth + 1)`, the CrosSplice alternative ratio |

The final output is `figure_directory/combined/crossplice_validation_combined_p.tsv`
(columns: `Key`, `Tissue`, `PV`, `SpliceAI_score`), where `PV` is the `-log10`
combined p-value.

<br>

## Computational requirements and runtime

Benchmark on the GTEx v7-scale dataset in our study (9,749 RNA-seq samples,
11,539 SSCV candidates). VEP annotation is a general preprocessing step and is
not included here.

| Step | Script / process | Resources used | Wall time |
|---|---|---:|---:|
| Filtering | `vep_filter_spliceai_gnomad.py` | 1 slot, 0.1 GB | ~25 min |
| Define primary novel / hijacked SJ | `run_define.sh` / `define_sj.py` | low memory | seconds to a few min |
| Validation | `2_validation/run.sh` | 2 slots, 130 GB/slot, 260 GB total | ~4 h 15 min |
| P-value / plotting | `3_plot/plot_figure.sh` | 1 slot, 200 GB | ~6 h |

The CrosSplice-specific steps after VEP annotation completed in ~11 hours for a
GTEx-scale analysis. Runtime and memory vary with the number of samples,
tissues, candidate variants, and file system performance.

<br>

## License

CrosSplice is free for academic use only.

If you are not a member of a public funded academic and/or education and/or research institution you must obtain a commercial license from National Cancer Center; please email Yuichi Shiraishi (yuishira@ncc.go.jp).

# =============================================================================
# CrosSplice — Snakemake workflow (Grid Engine (SGE/UGE) + Apptainer)
#
# Orchestrates the existing 1_prep/, 2_validation/ and 3_plot/ scripts.
# Run from the repository root (scripts are referenced with relative paths):
#   snakemake -n                      # dry run (inspect the DAG)
#   bash run.sh                       # launch on the cluster (see run.sh)
#   snakemake --profile profiles/gridengine
#
# The per-chromosome steps (preprocessing + VEP) and the per-split step
# (validation) are parallelised with wildcards and a checkpoint.
# =============================================================================
import os

configfile: "config.yaml"

# --- config-derived values ---------------------------------------------------
WDIR         = config["wdir"].rstrip("/")
INPUT_VCF    = config["input_vcf"]
CHR_PRE      = config["chr_pre"]
MODE         = config.get("mode", "direct")
GENOTYPE_VCF = config.get("genotype_vcf") or INPUT_VCF
SPLIT_SIZE   = int(config.get("split_size", 1000))
CHROMS       = [str(c) for c in config["chromosomes"]]

# input VCF stem (basename minus .vcf.gz / .vcf.bgz); used in prepared/post_vep names
STEM = os.path.basename(INPUT_VCF)
for _ext in (".vcf.gz", ".vcf.bgz"):
    if STEM.endswith(_ext):
        STEM = STEM[: -len(_ext)]
        break

# --- directory layout under WDIR ---------------------------------------------
PREPARED    = f"{WDIR}/prepared"
POST_VEP    = f"{WDIR}/post_vep"
POST_FILTER = f"{WDIR}/post_filter"
OUTPUT      = f"{WDIR}/output"
PLOT_DIR    = config.get("plot_dir") or f"{WDIR}/figure_directory"

# key files (fixed names must match the outputs hard-coded in the existing scripts)
FILTERED   = f"{POST_FILTER}/input.all.gnomad001.spliceaiG01.filtered.txt"
MERGE      = f"{OUTPUT}/cross_input.merge.txt"
VALIDATION = f"{OUTPUT}/cross.validation.txt"
COMBINED   = f"{PLOT_DIR}/combined/crossplice_validation_combined_p.tsv"

# validation intermediates
SPLIT_DIR   = f"{OUTPUT}/split"
MUTKEY_DIR  = f"{OUTPUT}/mutkey_work"
SJCOUNT_DIR = f"{OUTPUT}/sj_count"
FLAG_DIR    = f"{OUTPUT}/flags"


def res(rule, key, default):
    """Per-rule resource lookup from config['resources'][rule][key] with fallback."""
    return config.get("resources", {}).get(rule, {}).get(key, default)


def aggregate_mutkey_flags(wildcards):
    """After the split checkpoint, one mutkey job per split file (0, 1, 2, ...)."""
    ck = checkpoints.split_input.get(**wildcards)
    split_out = ck.output[0]
    idxs = glob_wildcards(os.path.join(split_out, "{i}")).i
    idxs = [i for i in idxs if i.isdigit()]  # split_file.py names files 0, 1, 2, ...
    return expand(f"{FLAG_DIR}/mutkey.{{i}}.done", i=sorted(idxs, key=int))


# =============================================================================
# Targets
# =============================================================================
rule all:
    input:
        COMBINED,


rule prep:          # stop after cross_input.merge.txt
    input:
        MERGE,


rule validation:    # stop after cross.validation.txt
    input:
        VALIDATION,


# =============================================================================
# Stage 1: preprocessing (per-chr) -> VEP (per-chr) -> filter (aggregate) -> define SJ
# =============================================================================

# 1a. Split the VCF per chromosome, (liftover,) sort and index.
rule proc_vcf:
    input:
        vcf=INPUT_VCF,
    output:
        vcf=f"{PREPARED}/{STEM}.{{chr}}.prepared.vcf.gz",
        tbi=f"{PREPARED}/{STEM}.{{chr}}.prepared.vcf.gz.tbi",
    params:
        wdir=WDIR,
        chr_pre=CHR_PRE,
        chain=config.get("chain_37to38", ""),
        liftover=config.get("liftover_bin", "liftOver"),
        mode=MODE,
    log:
        "log/proc_vcf/{chr}.log",
    threads: res("proc_vcf", "threads", 1)
    resources:
        mem_gb=res("proc_vcf", "mem_gb", 4),
    shell:
        r"""
        if [ "{params.mode}" = "lift" ]; then
            bash 1_prep/proc_vcf_liftover.sh "{wildcards.chr}" {params.wdir} {input.vcf} {params.chain} {params.chr_pre} {params.liftover} > {log} 2>&1
        else
            bash 1_prep/proc_vcf.sh "{wildcards.chr}" {params.wdir} {input.vcf} {params.chr_pre} > {log} 2>&1
        fi
        """


# 1b. VEP annotation (SpliceAI plugin + gnomAD custom); bgzip+tabix at the end -> .vcf.gz
rule vep_annotate:
    input:
        vcf=f"{PREPARED}/{STEM}.{{chr}}.prepared.vcf.gz",
    output:
        vcf=f"{POST_VEP}/{STEM}.{{chr}}.prepared.vep.vcf.gz",
        tbi=f"{POST_VEP}/{STEM}.{{chr}}.prepared.vep.vcf.gz.tbi",
    params:
        post_vep=POST_VEP,
        out_plain=f"{POST_VEP}/{STEM}.{{chr}}.prepared.vep.vcf",
        container=config.get("container_exec", "apptainer"),
        bind=config["bind_dir"],
        image=config["vep_image"],
        cache=config["vep_cache"],
        ref=config["reference"],
        gnomad=config["gnomad"],
        snv=config["spliceai_snv"],
        indel=config["spliceai_indel"],
    log:
        "log/vep/{chr}.log",
    threads: res("vep", "threads", 2)
    resources:
        mem_gb=res("vep", "mem_gb", 8),
    shell:
        r"""
        mkdir -p {params.post_vep}
        {params.container} exec --bind {params.bind} {params.image} \
            /bin/bash 1_prep/shell_vep_annot_germline.sh \
            {input.vcf} {params.out_plain} {params.cache} {params.ref} {params.gnomad} {params.snv} {params.indel} > {log} 2>&1
        """


# 1c. Filter (aggregate all chromosomes -> single filtered.txt).
# vep_filter_spliceai_gnomad.py globs all post_vep/*.prepared.vep.vcf.gz into one output.
rule filter:
    input:
        expand(f"{POST_VEP}/{STEM}.{{chr}}.prepared.vep.vcf.gz", chr=CHROMS),
    output:
        FILTERED,
    params:
        wdir=WDIR,
    log:
        "log/filter.log",
    threads: res("filter", "threads", 1)
    resources:
        mem_gb=res("filter", "mem_gb", 4),
    shell:
        r"""
        python3 1_prep/vep_filter_spliceai_gnomad.py {params.wdir} > {log} 2>&1
        """


# 1d. Define primary / hijacked SJ -> cross_input.merge.txt.
rule define_sj:
    input:
        FILTERED,
    output:
        MERGE,
    params:
        wdir=WDIR,
        gencode=config["gencode"],
        mane=config["mane"],
    log:
        "log/define_sj.log",
    threads: res("define_sj", "threads", 1)
    resources:
        mem_gb=res("define_sj", "mem_gb", 8),
    shell:
        r"""
        bash 1_prep/run_define.sh {params.wdir} {params.gencode} {params.mane} > {log} 2>&1
        """


# =============================================================================
# Stage 2: split (checkpoint) -> mutkey (per-split) -> sj_count -> merge
# =============================================================================

# 2a. Split merge.txt into chunks of split_size rows. The number of chunks is
#     unknown until runtime, hence a checkpoint.
checkpoint split_input:
    input:
        MERGE,
    output:
        directory(SPLIT_DIR),
    params:
        n=SPLIT_SIZE,
    log:
        "log/split_input.log",
    threads: 1
    resources:
        mem_gb=res("split_input", "mem_gb", 4),
    shell:
        r"""
        rm -rf {output}
        mkdir -p {output}
        python3 2_validation/split_file.py {input} {output}/ {params.n} > {log} 2>&1
        """


# 2b. mutkey per split (carrier calling + sjouttab expansion). All jobs write into
#     a shared mutkey_work/, but output names "{split_index}.{run}" never collide.
#     The real files are side effects; the DAG is tracked with flag files.
rule mutkey_one:
    input:
        split=f"{SPLIT_DIR}/{{i}}",
    output:
        flag=touch(f"{FLAG_DIR}/mutkey.{{i}}.done"),
    params:
        work=MUTKEY_DIR,
        vcf=GENOTYPE_VCF,
        sjtab=config["sjouttab_list"],
        chain=config.get("chain_38to37", ""),
        liftover=config.get("liftover_bin", "liftOver"),
        mode=MODE,
    log:
        "log/mutkey/{i}.log",
    threads: res("mutkey", "threads", 1)
    resources:
        mem_gb=res("mutkey", "mem_gb", 32),
    shell:
        r"""
        mkdir -p {params.work}
        if [ "{params.mode}" = "lift" ]; then
            python3 2_validation/mutkey_38lift37.py {input.split} {params.work} {params.chain} {params.vcf} {params.sjtab} {params.liftover} > {log} 2>&1
        else
            python3 2_validation/mutkey_38direct.py {input.split} {params.work} {params.vcf} {params.sjtab} > {log} 2>&1
        fi
        """


# 2c. Count reads from SJ.out.tab per run/sample (internal ProcessPoolExecutor).
rule sj_count:
    input:
        aggregate_mutkey_flags,
    output:
        directory(SJCOUNT_DIR),
    params:
        work=MUTKEY_DIR,
    log:
        "log/sj_count.log",
    threads: res("sj_count", "threads", 4)
    resources:
        mem_gb=res("sj_count", "mem_gb", 32),
    shell:
        r"""
        rm -rf {output}
        mkdir -p {output}
        python3 2_validation/sj_count.py {params.work}/ {output}/ {threads} > {log} 2>&1
        """


# 2d. Merge -> cross.validation.txt.
rule merge_validation:
    input:
        SJCOUNT_DIR,
    output:
        VALIDATION,
    log:
        "log/merge_validation.log",
    threads: 1
    resources:
        mem_gb=res("merge_validation", "mem_gb", 4),
    shell:
        r"""
        head -n 1 $(ls {input}/* | head -n 1) > {output}
        cat {input}/* | grep -v '^Chr' >> {output}
        """


# =============================================================================
# Stage 3: per-mutkey p-value (R, internal doParallel) -> combined p-value
# =============================================================================

# 3a. Per-tissue Wilcoxon -> Fisher's method -> per-mutkey tsv (+ optional pdf).
# The R script uses Sys.getenv("NSLOTS", 4) as its core count, so pass NSLOTS=threads.
# Set make_plots: true in config.yaml to also write a per-variant PDF under figure/
# (Alternative ratio by tissue, carrier vs non-carrier); off by default.
rule pvalue:
    input:
        VALIDATION,
    output:
        tsv=directory(f"{PLOT_DIR}/tsv"),
    params:
        plotdir=PLOT_DIR,
        do_plot="TRUE" if config.get("make_plots", False) else "FALSE",
    log:
        "log/pvalue.log",
    threads: res("pvalue", "threads", 4)
    resources:
        mem_gb=res("pvalue", "mem_gb", 60),
    shell:
        r"""
        mkdir -p {params.plotdir}/tsv
        if [ "{params.do_plot}" = "TRUE" ]; then mkdir -p {params.plotdir}/figure; fi
        NSLOTS={threads} Rscript ./3_plot/pararell_get_pvalue_spliceai.R {input} {params.plotdir} {params.do_plot} > {log} 2>&1
        """


# 3b. Aggregate the "Combined" row of each tsv -> combined p-value table (final output).
rule gather:
    input:
        tsv=f"{PLOT_DIR}/tsv",
    output:
        COMBINED,
    log:
        "log/gather.log",
    threads: res("gather", "threads", 1)
    resources:
        mem_gb=res("gather", "mem_gb", 4),
    shell:
        r"""
        mkdir -p $(dirname {output})
        python3 ./3_plot/gather_combined_p.py {input.tsv}/ {output} > {log} 2>&1
        """

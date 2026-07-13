# CrosSplice test dataset

A tiny, fully synthetic dataset for trying CrosSplice end-to-end and confirming
it detects a known splice-site-creating variant (SSCV). It is run with the
**normal CrosSplice entry points** (the Snakemake workflow or the step-by-step
scripts) — there is no separate "test-only" runner.

## What it is

The RNA-seq splice-junction data was produced with a **Polyester** simulation
(simulated reads → STAR → `SJ.out.tab`), so nothing derives from real
individuals and it is free to redistribute; the genotypes are the simulation's
ground truth. The scenario is tissue-specific (one carrier, 100 non-carrier
donors, 10 tissues; the novel junction appears in a subset of the carrier's
tissues). Two candidates are included:

| Candidate | Meaning | Expected `-log10` combined p |
|---|---|---|
| `chr22:38115172 C>T` (PLA2G6) | true SSCV | **~12.7** (detected, ≥ 8) |
| `chr22:38116000 G>A` (NEGCTRL) | negative control (carrier, no splicing effect) | **~0.2** (not detected) |

The dataset starts from `cross_input.merge.txt`, i.e. it exercises the
validation and p-value stages. It does **not** run the VEP/SpliceAI/gnomAD
preprocessing (which needs large databases).

## Extract

From the repository root:

```bash
tar xzf test/data.tar.gz -C test/
```

This creates `test/data/` (git-ignored):

```
test/data/
├── output/cross_input.merge.txt   # the two candidate SSCVs
├── genotype.vcf.gz (+ .tbi)        # carrier 0/1, donors 0/0
├── sjouttab_list.txt               # sample × tissue × SJ.out.tab path
└── sj/                             # 1010 tiny SJ.out.tab.gz (+ .tbi)
```

## Run it — option A: Snakemake (the normal workflow)

A ready-made config points the workflow at the extracted data:

```bash
snakemake --configfile test/config.test.yaml -c1 all
```

`all` runs validation → p-value → figures; use `... validation` to stop at
`test/data/output/cross.validation.txt`. The final table is
`test/data/figure_directory/combined/crossplice_validation_combined_p.tsv`.
(`config.test.yaml` sets `mode: direct` and placeholder database paths, since
preprocessing is skipped.)

## Run it — option B: step-by-step scripts

The same two production scripts documented in the main README (steps 5–6),
starting from the provided `cross_input.merge.txt`:

```bash
# validation: carrier calling + SJ read counting -> cross.validation.txt
bash 2_validation/run.sh \
    test/data/output/cross_input.merge.txt \
    test/data/output/cross.validation.txt \
    test/data/genotype.vcf.gz \
    1 direct NONE \
    test/data/sjouttab_list.txt

# p-value (+ optional figure): -> plot/combined/crossplice_validation_combined_p.tsv
bash 3_plot/plot_figure.sh \
    test/data/output/cross.validation.txt \
    test/data/plot \
    FALSE
```

## Expected result

The combined p-value table should contain:

```
Key                             Tissue    PV      ...
chr22_38115172_C_T_PLA2G6       Combined  ~12.70   <- detected (>= 8)
chr22_38116000_G_A_NEGCTRL      Combined  ~0.23    <- not detected
```

The exact PLA2G6 value is `12.700` (matches the corresponding Polyester
benchmark). Requires Python 3 with `pysam`, and R with `tidyverse`, `foreach`,
`doParallel`. Runs in seconds.

## How the dataset was built (provenance)

The bundled data is fully synthetic and was generated once, offline: RNA-seq reads were simulated with Polyester (scenario 4b), aligned with STAR to produce per-sample `SJ.out.tab`, and the junctions were assembled into a panel of 1 carrier + 100 non-carrier donors across 10 tissues, plus a negative control, producing `cross_input.merge.txt`, `genotype.vcf.gz` and `sjouttab_list.txt`. 
End users do not need to reproduce this — the packaged `data.tar.gz` is ready to use.

Note: the positive's significance depends strongly on the donor count (the
signal is a single novel-junction read set against many zero-count donors);
≈ 75 donors are needed to clear the threshold of 8, which is why the full
100-donor panel is bundled.


## References

**Polyester** — Frazee AC, Jaffe AE, Langmead B, Leek JT. Polyester: simulating
RNA-seq datasets with differential transcript expression. *Bioinformatics*.
2015;31(17):2778–2784. doi:[10.1093/bioinformatics/btv272](https://doi.org/10.1093/bioinformatics/btv272)

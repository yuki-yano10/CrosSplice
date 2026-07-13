#!/bin/bash
# =============================================================================
# CrosSplice launcher for a Grid Engine (SGE/UGE) cluster.
#
# Runs the Snakemake controller on the login node; each rule is submitted as an
# individual qsub job via the profile in profiles/gridengine/.
#
# Usage:
#   1. Edit config.yaml (paths and resources).
#   2. (optional) activate the environment that has Snakemake installed, e.g.:
#        source /path/to/venv/bin/activate
#   3. bash run.sh                 # full pipeline
#      bash run.sh -n              # dry run (any extra args are passed through)
#      bash run.sh prep            # stop after cross_input.merge.txt
#      bash run.sh validation      # stop after cross.validation.txt
# =============================================================================
set -euo pipefail

PROFILE="profiles/gridengine"

# Log directories (the profile writes cluster stdout/stderr under logs/cluster/,
# and each rule writes its own log under log/).
mkdir -p logs/cluster log

# All arguments are forwarded to Snakemake (target rules, -n, --rerun-incomplete, ...).
snakemake --profile "${PROFILE}" "$@"

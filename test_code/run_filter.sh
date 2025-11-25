#!/bin/bash
#$ -S /usr/bin/bash

WDIR=/home/yano_y/GTEX_validation_project/cros_test

python3 1_prep/vep_filter_spliceai_gnomad.py $WDIR

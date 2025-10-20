#!/bin/bash
#$ -S /usr/bin/bash

/usr/local/package/singularity/3.7.3/bin/singularity exec --bind /home/yano_y/GTEX_validation_project /home/yano_y/juncmut-paper_0.0.1.simg /bin/bash /home/yano_y/GTEX_validation_project/plot_code/plot_figure.sh


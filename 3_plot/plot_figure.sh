PLOT_DIR=$2
INPUT=$1

# calc p-value
# 最後のオプションはプロット出力フラグ
mkdir -p ${PLOT_DIR}/tsv ${PLOT_DIR}/figure
Rscript ./3_plot/pararell_get_pvalue_spliceai.R ${INPUT} ${PLOT_DIR}

# combine p-values
mkdir -p ${PLOT_DIR}/combined
python ./3_plot/gather_combined_p.py ${PLOT_DIR}/tsv/ ${PLOT_DIR}/combined/crossplice_validation_combined_p.tsv

PLOT_DIR=$2
INPUT=$1
PLOT_CODE=$3

# calc p-value
# 最後のオプションはプロット出力フラグ
mkdir -p ${PLOT_DIR}/tsv
Rscript ./code/pararell_get_pvalue_spliceai.R ${INPUT} ${PLOT_DIR} ${PLOT_CODE}

# combine p-values
mkdir -p ${PLOT_DIR}/combined
python ./code/gather_combined_p.py ${PLOT_DIR}/tsv/ ${PLOT_DIR}/combined/crossplice_validation_combined_p.tsv

# plot (各プロジェクトで用意したスクリプトを使用)
#Rscript /path/to/plot.R ${PLOT_DIR}/combined/gtex_validation_combined_p.tsv ${PLOT_DIR}/combined/plot_gtex_validation_combined.pdf

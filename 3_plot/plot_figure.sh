PLOT_DIR=$2
INPUT=$1
PLOT_CODE=$3

# calc p-value
# 最後のオプションはプロット出力フラグ
mkdir -p ${PLOT_DIR}/tsv
/usr/local/package/r/4.3.2/bin/Rscript /home/yano_y/GTEX_validation_project/plot_code_virtual/pararell_get_pvalue_spliceai.R ${INPUT} ${PLOT_DIR} ${PLOT_CODE}

# combine
#rm -rf ${PLOT_DIR}/combined
mkdir -p ${PLOT_DIR}/combined
python /home/yano_y/GTEX_validation_project/plot_code/gather_combined_p.py ${PLOT_DIR}/tsv/ ${PLOT_DIR}/combined/gtex_validation_combined_p.tsv

# plot (各プロジェクトで用意したスクリプトを使用)
#Rscript /path/to/plot.R ${PLOT_DIR}/combined/gtex_validation_combined_p.tsv ${PLOT_DIR}/combined/plot_gtex_validation_combined.pdf

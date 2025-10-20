library(tidyverse)
library(foreach)
library(doParallel)

# 引数処理
args <- commandArgs(trailingOnly = TRUE)
input_file <- args[1]
output_dir <- args[2]
do_plot <- args[3]

# データ読み込みと前処理
D <- read.delim(input_file, sep="\t", header=TRUE)
D$Tissue2 <- unlist(lapply(strsplit(D$Tissue, "\\."), function(x) {sub("_", " ", x[2])}))
D <- D %>% mutate(MutKey2 = paste(Chr, Position, Ref, Alt, sep=",")) %>%mutate(MutKey2 = paste(MutKey2, Gene)) %>%filter(Depth!=0)
D <- D %>% mutate(Is_Mutation = as.character(Is_Mutation))

mutkey_list <- D %>% filter(Is_Mutation == "True") %>% select(MutKey2) %>% unique() %>% pull()

# 並列化の準備
cores <- as.integer(Sys.getenv("NSLOTS", unset=4))  # 環境変数NSLOTSがあれば使う（SGE対応）
cl <- makeCluster(cores)
registerDoParallel(cl)

# 並列実行
foreach(mutkey = mutkey_list, .packages = c("tidyverse")) %dopar% {

	get_pvalue_table <- function(mutkey, table_file) {
		D2 <- D %>% filter(MutKey2 == mutkey) %>% filter(Depth !=0)
		tissue_list <- D2 %>% filter(Is_Mutation == "True") %>% select(Tissue2) %>% unique() %>% pull()
		D3 <- D2 %>% filter(Tissue2 %in% tissue_list)
					        
		ai_score = D3$SpliceAI_score[1]
		tDF <- data.frame()
		for (tissue in tissue_list) {
			tD3 <- D3 %>% filter(Tissue2 == tissue)
		        pos_values <- tD3 %>% filter(Is_Mutation == "True") %>% pull(Ratio)
		        neg_values <- tD3 %>% filter(Is_Mutation == "False") %>% pull(Ratio)
			if (length(pos_values) == 0 || length(neg_values) == 0) break
			tpvalue <- wilcox.test(pos_values, neg_values, alternative = "greater", correct = TRUE, exact=FALSE)$p.value
			tDF <- rbind(tDF, data.frame(Tissue = tissue, PV = tpvalue, SpliceAI_score = ai_score))
		}

		if (length(tDF) > 0) {
			tpvalue <- pchisq(sum(-2 * log(tDF$PV)), df = length(tDF$PV) * 2, lower.tail = FALSE)
			if (tpvalue < 1.0e-320) tpvalue_log <- -log10(1.0e-320)
			else tpvalue_log <- -log10(tpvalue)
			tDF <- rbind(tDF, data.frame(Tissue = "Combined", PV = tpvalue_log, SpliceAI_score = ai_score))
			write_tsv(tDF, table_file)
		}
	}

	s1 <- sub(" ", "_", mutkey)
	s2 <- gsub(",", "_", s1)
	table_file <- paste0(output_dir, "/tsv/gtex_validation_", s2, "_pvalue.tsv")
	get_pvalue_table(mutkey, table_file)

	if (do_plot == "TRUE") {
		plot_file <- paste0(output_dir, "/figure/gtex_validation_", s2, "_MutPosTissue.pdf")
		mutkey_plot(mutkey, plot_file)  # 必要ならこの関数もスコープ内に入れる
	}
}

				      
# クラスターを停止
stopCluster(cl)


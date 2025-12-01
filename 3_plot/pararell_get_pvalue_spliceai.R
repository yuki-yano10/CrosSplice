library(tidyverse)
library(foreach)
library(doParallel)

# Argument processing
args <- commandArgs(trailingOnly = TRUE)
input_file <- args[1]
output_dir <- args[2]
do_plot <- args[3]

# Set the graph theme for plotting.
my_theme <- function() {
	theme_minimal(base_family = "Helvetica")+
	theme(title = element_text(size = 8),
	panel.border = element_blank(),
        panel.grid.major = element_blank(),
	panel.grid.minor = element_blank(),
	plot.margin = unit(c(0.21, 0.21, 0.21, 0.21), "lines"),
	axis.line = element_line(colour = "grey20", size = 0.5), 
	axis.text = element_text(size = 8),
	axis.title = element_text(size = 8),
	axis.title.y = element_text(angle = 90),
	legend.key = element_blank(), 
	legend.key.size = unit(0.25, "cm"),
	legend.margin = margin(0.5, 0.5, 0.5, 0.5),
	legend.text = element_text(size = 8),
	strip.text = element_text(size = 8),
	#strip.background = element_rect(fill = "white", colour = "black", size = 1),
	strip.background = element_blank(), 
	panel.background = element_blank(),
	complete = TRUE)
}


mutkey_plot <- function(mutkey, plot_file) {
	D2 <- D %>% filter(MutKey2 == mutkey) %>% filter(Depth != 0)
        tissue_list <- D2 %>% select(Tissue2) %>% unique() %>% pull()
        D3 <- D2 %>% filter(Tissue2 %in% tissue_list)
        mkey <- str_replace_all(unlist(str_split(mutkey, pattern = ' '))[1], ',', '-')
        mgene <- unlist(str_split(mutkey, pattern = ' '))[2]
        p <- ggplot(D3 %>% arrange(Is_Mutation), aes(x = Tissue2, y = Primary_read_count / (Depth + 1), color = Is_Mutation, alpha = Is_Mutation)) + 
		geom_jitter(width = 0.1,height=0, size = 0.75) +
		labs(x = "", y = "Alternative ratio", colour = "Is_Mutation", alpha = "Is_Mutation") +
		ggtitle(bquote(italic(.(mgene))~' '~.(mkey))) +
		my_theme() +
		theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
		      axis.text = element_text(size = 8)) + 
                scale_colour_manual(values = c("TRUE" = "#ff7f00", "FALSE" = "#999999")) + 
		scale_alpha_manual(values = c("TRUE" = 1, "FALSE" = 0.25)) + 
		guides(color = FALSE, alpha = FALSE)

      ggsave(plot_file, width = 14, height = 10, units = "cm")
}



# Data loading
D <- read.delim(input_file, sep="\t", header=TRUE)
D$Tissue2 <- unlist(lapply(strsplit(D$Tissue, "\\."), function(x) {sub("_", " ", x[2])}))
D <- D %>% mutate(MutKey2 = paste(Chr, Position, Ref, Alt, sep=",")) %>%mutate(MutKey2 = paste(MutKey2, Gene)) %>%filter(Depth!=0)
D <- D %>% mutate(Is_Mutation = as.character(Is_Mutation))

mutkey_list <- D %>% filter(Is_Mutation == "True") %>% select(MutKey2) %>% unique() %>% pull()

# Prepation for pararell processing
cores <- as.integer(Sys.getenv("NSLOTS", unset=4))
cl <- makeCluster(cores)
registerDoParallel(cl)

# Pararell processing
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
		mutkey_plot(mutkey, plot_file)
	}
}

				      

stopCluster(cl)


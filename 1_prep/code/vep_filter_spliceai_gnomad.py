#!/usr/local/package/python/3.6.5/bin/python
#$ -S /usr/local/package/python/3.6.5/bin/python

    
import gzip

chr_list="1, 2, 3, 4,5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, X"
output_file = "/home/yano_y/GTEX_validation_project_V8/post_filter/GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_866Indiv.all.gnomad001.spliceaiG01.txt"

with open(output_file, "w") as hout:
    header = "Mut_key\tChr\tPos\tRef\tAlt\tGene\tSpliceAI_pred_DP_AG\tSpliceAI_pred_DP_AL\tSpliceAI_pred_DP_DG\tSpliceAI_pred_DP_DL\tSpliceAI_pred_DS_AG\tSpliceAI_pred_DS_AL\tSpliceAI_pred_DS_DG\tSpliceAI_pred_DS_DL\tSpliceAI_pred_SYMBOL\tgnomADg_AF\n"
    hout.write(header)
    
    for i in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,"X"]:
        input_vcf = "/home/yano_y/GTEX_validation_project/post_vep/GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_866Indiv.chr"+str(i)+".sorted.rare-variant.vep.vcf.gz"
        output_vcf = "/home/yano_y/GTEX_validation_project/post_filter/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller."+ str(i) +".lift38.gnomad001.spliceaiG01.vcf"
        
        with gzip.open(input_vcf, 'rt') as hin, open(output_vcf,"w") as vout:
           for line in hin:
              F = line.rstrip('\n').split('\t')
              if F[0].startswith("##"):
                 vout.write(line)
              elif F[0].startswith("#CHROM"):
                 vout.write(line)            
              else:
                 chr = F[0]
                 pos = F[1]
                 ref = F[3]
                 alt = F[4]
                 key = chr +","+ pos +","+ ref +","+ alt
                 info = F[7]
                         
                 if F[6] == "PASS" and len(ref) == 1 and len(alt) == 1:
                   I = info.split(";")
                   for i in I:
                      if i.startswith("CSQ"):
                         annot = i.replace("CSQ=","")
                         A = annot.split("|")
                         gene = A[3]
                         SpliceAI_pred_DS_AG = A[43]
                         SpliceAI_pred_DS_DG = A[45]
                         gnomADg_AF = A[55]
                                
                         if SpliceAI_pred_DS_AG == "" or SpliceAI_pred_DS_DG == "": 
                             continue
                         if float(SpliceAI_pred_DS_AG) >= 0.1 or float(SpliceAI_pred_DS_DG) >= 0.1:
                             if gnomADg_AF == "":
                                gnomADg_AF = 0
                                rec = key +"\t"+ str(chr) +"\t"+ str(pos) +"\t"+ ref +"\t"+ alt +"\t"+ gene +"\t"+ "\t".join(A[39:48]) +"\t"+ str(gnomADg_AF) +"\n"
                                hout.write(rec)
                                vout.write(line)
                                
                             elif float(gnomADg_AF) < 0.01:
                                rec = key +"\t"+ str(chr) +"\t"+ str(pos) +"\t"+ ref +"\t"+ alt +"\t"+ gene +"\t"+ "\t".join(A[39:48]) +"\t"+ str(gnomADg_AF)+"\n"
                                hout.write(rec)
                                vout.write(line)
                             else: continue

                                

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
    
import gzip
import sys
import os
from pathlib import Path

working_directory = sys.argv[1]

input_dir = Path(f"{working_directory}/post_vep")
input_files = sorted(input_dir.glob("*.prepared.vep.vcf.gz"))

output_dir = Path(f"{working_directory}/post_filter")
os.makedirs(output_dir, exist_ok=True)
output_file = f"{output_dir}/input.all.gnomad001.spliceaiG01.filtered.txt"

with open(output_file, "w") as hout:
    header = "Mut_key\tChr\tPos\tRef\tAlt\tGene\tSpliceAI_pred_DP_AG\tSpliceAI_pred_DP_AL\tSpliceAI_pred_DP_DG\tSpliceAI_pred_DP_DL\tSpliceAI_pred_DS_AG\tSpliceAI_pred_DS_AL\tSpliceAI_pred_DS_DG\tSpliceAI_pred_DS_DL\tSpliceAI_pred_SYMBOL\tgnomADg_AF\n"
    hout.write(header)
    
    for input_vcf in input_files:
        stem = input_vcf.name.replace(".prepared.vep.vcf.gz", "")
        output_vcf = output_dir / f"{stem}.gnomad001.spliceaiG01.vcf.gz"

        print(f"Input : {input_vcf}")
        print(f"Output : {output_vcf}")
        
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
                         gnomADg_AF = A[49]
                                
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

                                

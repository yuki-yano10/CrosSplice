#!/usr/bin/env python3
# -*- coding: utf-8 -*-


from argparse import ArgumentParser               
import subprocess
import os


def add_chr(input_vcf, output_vcf):

    import gzip
    
    with gzip.open(input_vcf, 'rt') as hin, open(output_vcf, "w") as hout:

        for line in hin:
            F = line.rstrip('\n').split('\t')
            if F[0].startswith("##"):
                if F[0].startswith("##contig=<ID="):
                    new_contig=F[0].replace("contig=<ID=", "contig=<ID=chr")
                    hout.write(new_contig+"\n")
                    continue
                else:
                    hout.write(line)
                    continue
            if F[0].startswith("#CHROM"):
                #rec = '\t'.join(F[:8]) +"\n"                   
                hout.write(line)
                continue
            
            chr = F[0]
            new_chr = "chr" + chr
            pos = F[1]
        
            if new_chr == target:
        
                rec = new_chr + "\t" + str(pos) +"\t"+ '\t'.join(F[2:]) +"\n"   
                hout.write(rec)
                
                       
           
if __name__ == "__main__":

    parser = ArgumentParser()

    parser.add_argument("-input_vcf", action="store", dest="vcf", help="vcf file", required=True)
    parser.add_argument("-output_vcf", action="store", dest="output", help="output file", required=True)
    o = parser.parse_args()

    add_chr(o.input_vcf, o.output_vcf)

#!/usr/bin/env python3
# -*- coding: utf-8 -*-


from argparse import ArgumentParser               
import subprocess
import os
import gzip

def add_chr(vcf, output):
    with gzip.open(vcf, 'rt') as hin, open(output, "w") as hout:
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
                hout.write(line)
                continue
            else:
                chr = F[0]
                new_chr = "chr" + str(chr)
                pos = F[1]
        
                rec = new_chr + "\t" + str(pos) +"\t"+ '\t'.join(F[2:]) +"\n"   
                hout.write(rec)
                
                       
           
if __name__ == "__main__":

    parser = ArgumentParser()

    parser.add_argument("-vcf", action="store", dest="vcf", help="vcf file", required=True)
    parser.add_argument("-output", action="store", dest="output", help="output file", required=True)
    o = parser.parse_args()

    add_chr(o.vcf, o.output)

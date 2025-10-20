#!/usr/bin/env python3
# -*- coding: utf-8 -*-


from argparse import ArgumentParser 

def tidy_chr(input_file, output_file, target):
    
    with open(input_file, 'r') as hin, open(output_file, "w") as hout:

        for line in hin:
            F = line.rstrip('\n').split('\t')
            if F[0].startswith("##"):
                hout.write(line)
                continue
        
            if F[0].startswith("#CHROM"):
                #rec = '\t'.join(F[:8]) +"\n"                   
                hout.write(line)
                continue
            
            chr = F[0]
            if chr == target:
                hout.write(line)
                
if __name__ == "__main__":

    parser = ArgumentParser()

    parser.add_argument("-input_file", action="store", dest="input_file", help="vcf file", required=True)
    parser.add_argument("-output_file", action="store", dest="output_file", help="output file", required=True)
    parser.add_argument("-target", action="store", dest="target", help="target chr", required=True)
    o = parser.parse_args()

    tidy_chr(o.input_file, o.output_file, o.target)
            


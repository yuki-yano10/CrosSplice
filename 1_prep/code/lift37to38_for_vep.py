#!/usr/bin/env python3
# -*- coding: utf-8 -*-


from argparse import ArgumentParser               
import subprocess
import os


def lift37to38_for_vep(vcf, output, chain, target):

    import gzip
    
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
                #rec = '\t'.join(F[:8]) +"\n"                   
                hout.write(line)
                continue
            
            chr = F[0]
            pos = F[1]
            mut_position =  "chr"+chr+"\t"+str(pos)+"\t"+str(int(pos)+1)
            
            with open(output+".q.bed", 'w') as bout:
                bout.write(mut_position + "\n")
            
            liftover_commands = ["/home/yano_y/tool/liftOver", output+".q.bed", chain, output+".lift.bed", output+".unmap.bed"]
            subprocess.call(liftover_commands)
        
            new_pos = "-"
            with open(output+".lift.bed", "r") as lin:
                for row in lin:
                    R=row.rstrip('\n').split('\t')
                    new_chr = R[0]
                    new_pos = R[1]
            
            if new_pos == "-": continue
        
            if new_chr == target:
        
                rec = new_chr + "\t" + str(new_pos) +"\t"+ '\t'.join(F[2:]) +"\n"   
                hout.write(rec)

            os.remove(output+".q.bed")
            os.remove(output+".lift.bed")
            os.remove(output+".unmap.bed")    
                
                       
           
if __name__ == "__main__":

    parser = ArgumentParser()

    parser.add_argument("-vcf", action="store", dest="vcf", help="vcf file", required=True)
    parser.add_argument("-output", action="store", dest="output", help="output file", required=True)
    parser.add_argument("-chain", action="store", dest="chain", help="chain file", required=True)
    parser.add_argument("-target", action="store", dest="target", help="target", required=True)
    o = parser.parse_args()

    lift37to38_for_vep(o.vcf, o.output, o.chain, o.target)

#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import glob
import csv
import math

def gather_combined_p(input_dir, output_file):
    fieldnames = [
        "Key",
        "CrosSplice_score",
        "SpliceAI_score",
    ]

    with open(output_file, 'w') as hout:
        csvwriter = csv.DictWriter(
            hout,
            delimiter = "\t",
            lineterminator="\n",
            fieldnames=fieldnames,
        )
        csvwriter.writeheader()

        
        for file in glob.glob(input_dir + "/gtex_validation_*_pvalue.tsv"):
            key = file.split('/')[-1].replace("gtex_validation_", "").replace("_pvalue.tsv", "")
            with open(file, 'r') as hin:
                csvreader = csv.DictReader(hin, delimiter='\t')

                for csvobj in csvreader:
                    if csvobj["Tissue"] == "Combined":
                        csvwriter.writerow({
                            "Key" : key,
                            "CrosSplice_score" : csvobj["PV"]
                            "SpliceAI_score" : csvobj["SpliceAI_score"],
                        })
                        break


if __name__ == "__main__":
    import sys
    input_dir = sys.argv[1]
    output_file = sys.argv[2]
    gather_combined_p(input_dir, output_file)

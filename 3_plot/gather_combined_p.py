#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: Naoko Iida

"""

import glob
import csv
import math

def gather_combined_p(input_dir, output_file):

    with open(output_file, 'w') as hout:
        csvwriter = None
        for file in glob.glob(input_dir + "/gtex_validation_*_pvalue.tsv"):
            key = file.split('/')[-1].replace("gtex_validation_", "").replace("_pvalue.tsv", "")
            with open(file, 'r') as hin:
                csvreader = csv.DictReader(hin, delimiter='\t')
                if csvwriter is None:
                    csvwriter = csv.DictWriter(hout, delimiter='\t', lineterminator='\n', fieldnames=["Key"] + csvreader.fieldnames)
                    csvwriter.writeheader()
                for csvobj in csvreader:
                    if csvobj["Tissue"] == "Combined":
                        csvobj["Key"] = key
                        print(csvobj)
                        csvwriter.writerow(csvobj)

if __name__ == "__main__":
    import sys
    input_dir = sys.argv[1]
    output_file = sys.argv[2]
    gather_combined_p(input_dir, output_file)

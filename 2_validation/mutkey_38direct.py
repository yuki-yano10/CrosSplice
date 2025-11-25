#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
chain = "hg38ToHg19.over.chain"
"""

import gzip
import pysam
import subprocess
import os
import csv
import copy
import json



def check_chr(vcf_file):
    vcf_has_chr= False
    with gzip.open(vcf_file, "rt") as hin:
        for line in hin:
            if line.startswith("#CHROM"):
                continue
            if not line.startswith("##"):
                chrom = line.split("\t")[0]
                vcf_has_chr = chrom.startswith("chr")
                break
    
    return vcf_has_chr


def mutkey_direct(input_file, output_dir, vcf_file, sjouttab_list):
    vcf_has_chr = check_chr(vcf_file)
    print("vcf_has_chr: ", vcf_has_chr)
    sjouttab_dict = {}
    with open(sjouttab_list, 'r') as hin:
        csvreader = csv.DictReader(hin, delimiter='\t')
        for csvobj in csvreader:
            sjouttab_dict.setdefault(csvobj["Repository_sample_id"], []).append({"Run": csvobj["Run"], "Tissue": csvobj["Tissue"], "Path": csvobj["Path"]})

    ind2sample = {}
    with gzip.open(vcf_file, 'rt') as hin:
        for line in hin:
            if line.startswith("##"):
                continue
            if line.startswith("#CHROM"):
                F = line.rstrip('\n').split('\t')
                for i in range(9, len(F)):
                    ind2sample[i] = F[i]
                break
    
    output_prefix = "%s/%s" % (output_dir, os.path.basename(input_file))
    
    gtex_tb = pysam.TabixFile(vcf_file)
    writeobj_sjouttab = {}
    csvheader = ""
    with open(input_file, 'r') as hin:
        csvreader = csv.DictReader(hin, delimiter='\t')
        csvheader = csvreader.fieldnames
        for csvobj in csvreader:
            mut_key_chr = csvobj["Chr"]
            if vcf_has_chr:
                region_chr = mut_key_chr
            else:
                region_chr = mut_key_chr.replace("chr", "")

            pos = int(csvobj["Position"])

            region = "%s:%s-%d" % (region_chr, pos, pos + 1)
            gtex_records = None
            try:
                gtex_records = gtex_tb.fetch(region = region)
            except Exception as e:
                print(e)
            if gtex_records == None:
                continue

            csvobj["Chr38"] = region_chr
            csvobj["Position38"] = pos
            mkey38 = ",".join(map(str, [region_chr, pos, csvobj["Ref"], csvobj["Alt"]]))
            for record in gtex_records:
                R = record.split("\t")
                if ",".join([R[0], R[1], R[3], R[4]]) != mkey38:
                    continue
                for ind in range(9, len(R)):
                    sample = ind2sample[ind]
                    if not sample in sjouttab_dict:
                        continue
                    mut = "NA"
                    GT = R[ind].split(':')[0]
                    if GT in ["1/0", "0/1", "1/1"]:
                        mut = "True"
                    elif GT in ["0/0"]:
                        mut = "False"

                    for item in sjouttab_dict[sample]:
                        writeobj = copy.deepcopy(csvobj)
                        writeobj["Is_Mutation"] = mut
                        writeobj["Repository_sample_id"] = sample
                        writeobj["Run"] = item["Run"]
                        writeobj["Tissue"] = item["Tissue"]
                        writeobj["SJ_out_tab_path"] = item["Path"]
                        if not item["Run"] in writeobj_sjouttab:
                            writeobj_sjouttab[item["Run"]] = {}
                        key = json.dumps(writeobj)
                        writeobj_sjouttab[item["Run"]][key] = writeobj
                        print(writeobj)

    for run in writeobj_sjouttab:
        with open("%s.%s" % (output_prefix, run), "w") as hout:
            csvwriter = csv.DictWriter(hout, delimiter='\t', lineterminator='\n', fieldnames=csvheader + [
                "Chr38", "Position38", "Is_Mutation", "Repository_sample_id", "Run", "Tissue", "SJ_out_tab_path"
            ])
            csvwriter.writeheader()
            csvwriter.writerows(writeobj_sjouttab[run].values())

if __name__ == "__main__":
    import sys
    input_file = sys.argv[1]
    output_dir = sys.argv[2]
    vcf_file = sys.argv[3]
    sjouttab_list = sys.argv[4]

    mutkey_direct(input_file, output_dir, vcf_file, sjouttab_list)

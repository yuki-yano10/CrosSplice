#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import csv
import gzip
import pysam
import json

GENCODE_HEADER = [
  'bed_chrom',
  'bed_srat',
  'bed_end',
  'bin',
  'name',
  'chrom',
  'strand',
  'txStart',
  'txEnd',
  'cdsStart',
  'cdsEnd',
  'exonCount',
  'exonStarts',
  'exonEnds',
  'score',
  'name2',
  'cdsStartStat',
  'cdsEndStat',
  'exonFrames'
]

def shortest_hijacked_sj_size_tx(tx_info_list):
    if len(tx_info_list) == 0:
        return None

    # priority: the shortest hijacked_sj_size
    dict_sorted = sorted(tx_info_list.items(), key=lambda x:x[1], reverse=False)
    result = dict_sorted[0][0]
    (mutation_chr, primary_ss, matching_ss, hijacked_ss, sj_type, gencode_strand, mane) = result.split(',')

    if (sj_type == "DG" and gencode_strand == "+") or (sj_type == "AG" and gencode_strand == "-"):
        primary_sj = "%s:%s-%s" % (mutation_chr, primary_ss, matching_ss)
        hijacked_sj = "%s:%s-%s" % (mutation_chr, hijacked_ss, matching_ss)
    else:
        primary_sj = "%s:%s-%s" % (mutation_chr, matching_ss, primary_ss)
        hijacked_sj = "%s:%s-%s" % (mutation_chr, matching_ss, hijacked_ss) 

    return (primary_sj, hijacked_sj, mane)

def define_transcript_sj(sj_type, mutation_chr, mutation_pos, symbol, gencode_tb, mane_json):
    
    gencode_records = gencode_tb.fetch(region = "%s:%d-%d" % (mutation_chr, mutation_pos, mutation_pos + 1))
    if gencode_records == None:
        gencode_records = []

    tx_info_mane = {}
    tx_info_mane_clinical = {}
    tx_info_not_mane = {}
    for record in gencode_records:
        F = record.rstrip('\n').split('\t')
        gencode_chrom = F[GENCODE_HEADER.index("chrom")]
        gencode_name2 = F[GENCODE_HEADER.index("name2")]
        if gencode_name2 != symbol:
            continue

        gencode_name = F[GENCODE_HEADER.index("name")]
        gencode_strand = F[GENCODE_HEADER.index("strand")]
        gencode_exon_starts = list(map(int, F[GENCODE_HEADER.index("exonStarts")].rstrip(',').split(',')))
        gencode_exon_ends = list(map(int, F[GENCODE_HEADER.index("exonEnds")].rstrip(',').split(',')))

        hijacked_sj_size = None
        if (sj_type == "DG" and gencode_strand == "+") or (sj_type == "AG" and gencode_strand == "-"):
            for i in range(len(gencode_exon_starts)-1):
                if gencode_exon_starts[i] < mutation_pos < gencode_exon_starts[i+1]:
                    primary_ss = mutation_pos + 1
                    hijacked_ss = gencode_exon_ends[i] + 1
                    matching_ss = gencode_exon_starts[i+1]
                    hijacked_sj_size = matching_ss - hijacked_ss
                    key = "%s,%d,%d,%d,%s,%s" % (mutation_chr, primary_ss, matching_ss, hijacked_ss, sj_type, gencode_strand)
                    break

        elif (sj_type == "DG" and gencode_strand == "-") or (sj_type == "AG" and gencode_strand == "+"):
            for i in range(len(gencode_exon_starts)-1):
                if gencode_exon_ends[i] < mutation_pos < gencode_exon_ends[i+1]:
                    primary_ss = mutation_pos - 1
                    hijacked_ss = gencode_exon_starts[i+1]
                    matching_ss = gencode_exon_ends[i] + 1
                    hijacked_sj_size = hijacked_ss - matching_ss
                    key = "%s,%d,%d,%d,%s,%s" % (mutation_chr, primary_ss, matching_ss, hijacked_ss, sj_type, gencode_strand)
                    break

        if not hijacked_sj_size is None:
            if gencode_name in mane_json:
                if mane_json[gencode_name]["tag"] == "MANE_Select":
                    tx_info_mane[key + ",MANE_Select"] = hijacked_sj_size
                elif mane_json[gencode_name]["tag"] == "MANE_Plus_Clinical":
                    tx_info_mane_clinical[key + ",MANE_Plus_Clinical"] = hijacked_sj_size
                else:
                    tx_info_not_mane[key + ",not_MANE_tag"] = hijacked_sj_size
            else:
                tx_info_not_mane[key + ",unmatched_MANE"] = hijacked_sj_size

    result = shortest_hijacked_sj_size_tx(tx_info_mane)
    if result is None:
        result = shortest_hijacked_sj_size_tx(tx_info_mane_clinical)
    if result is None:
        result = shortest_hijacked_sj_size_tx(tx_info_not_mane)

    if result is None:
        return ("NA", "NA", "NA")
    return result

def define_sj(input_file_list, output_file, gencode, mane):
    input_files = []
    with open(input_file_list) as hin:
        input_files = hin.read().split("\n")

    gencode_tb = pysam.TabixFile(gencode)
    
    with open(mane, 'r') as hin_mane:
        mane_json = json.load(hin_mane)

    writed_key = {}
    with open(output_file, 'w') as hout:
        csvwriter = csv.DictWriter(hout, delimiter='\t', lineterminator='\n', fieldnames=[
            "Chr", "Position", "Ref", "Alt", "Primary_SJ", "Hijacked_SJ", "Gene", "SpliceAI_score", "MANE"])
        csvwriter.writeheader()

        for input_file in input_files:
            if input_file == "":
                continue

            with open(input_file, 'r') as hin:
                csvreader = csv.DictReader(hin, delimiter='\t')
                for csvobj in csvreader:
                    mutation_chr = csvobj["Chr"]
                    pos = int(csvobj["Pos"])
                    DP_AG = float(csvobj["SpliceAI_pred_DP_AG"])
                    DP_DG = float(csvobj["SpliceAI_pred_DP_DG"])
                    DS_AG = float(csvobj["SpliceAI_pred_DS_AG"])
                    DS_DG = float(csvobj["SpliceAI_pred_DS_DG"])
                    symbol = csvobj["SpliceAI_pred_SYMBOL"]
                    
                    if DS_AG > DS_DG:
                        sj_type = "AG"
                        score = DS_AG
                        mutation_pos = int(round(float(pos) + DP_AG))
                        primary_sj, hijacked_sj, mane = define_transcript_sj(sj_type, mutation_chr, mutation_pos, symbol, gencode_tb, mane_json)
                            
                    else:
                        sj_type = "DG"
                        score = DS_DG
                        mutation_pos = int(round(float(pos) + DP_DG))
                        primary_sj, hijacked_sj, mane = define_transcript_sj(sj_type, mutation_chr, mutation_pos, symbol, gencode_tb, mane_json)
                        

                    if primary_sj == "NA": continue
                    key = (mutation_chr, pos, csvobj["Ref"], csvobj["Alt"], primary_sj, hijacked_sj, symbol)
                    if key in writed_key:
                        continue
                    csvwriter.writerow({
                        "Chr": mutation_chr, 
                        "Position": pos,
                        "Ref": csvobj["Ref"],
                        "Alt": csvobj["Alt"],
                        "Primary_SJ": primary_sj,
                        "Hijacked_SJ": hijacked_sj,
                        "Gene": symbol, 
                        "SpliceAI_score": max(DS_AG, DS_DG),
                        "MANE": mane,
                    })
                    writed_key[key] = None
                
if __name__ == "__main__":
    import sys

    input_file_list = sys.argv[1]
    output_file = sys.argv[2]
    gencode = sys.argv[3]
    mane = sys.argv[4]
    define_sj(input_file_list, output_file, gencode, mane)


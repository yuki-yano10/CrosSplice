#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import pysam
import csv
import os

def sj_screening(input_files, output_file):
    with open(output_file, "w") as hout:
        csvwriter = None
        last_sjouttab = ""
        junc_tb = None

        for input_file in input_files:
            with open(input_file, 'r') as hin:
                csvreader = csv.DictReader(hin, delimiter='\t')

                exclude_output_columns = {
                    "MANE",
                    "Chr37",
                    "Chr38",
                    "Position38",
                }

                base_fiednames = [
                    field
                    for field in csvreader.fieldnames
                    if field not in exclude_output_columns
                ]
                if csvwriter is None:
                    csvwriter = csv.DictWriter(hout, delimiter='\t', lineterminator='\n', fieldnames=base_fieldnames + [
                        "Primary_read_count", "Hijacked_read_count", "Total_junction_read_count", "Alternative_ratio"
                    ])
                    csvwriter.writeheader()
                for csvobj in csvreader:
                    sjouttab = csvobj["SJ_out_tab_path"]
                    if last_sjouttab != "" and last_sjouttab != sjouttab:
                        raise Exception ("sjouttab mismatch: %s" % (input_file))
                    last_sjouttab = sjouttab
                    
                    if junc_tb is None:
                        junc_tb = pysam.TabixFile(sjouttab)

                    primary_sj = csvobj["Primary_SJ"]
                    hijacked_sj = csvobj["Hijacked_SJ"]

                    primary_sj_split = primary_sj.split(':')
                    primary_chr = primary_sj_split[0]
                    primary_sj_pos = primary_sj_split[1].split('-')
                    primary_pos1 = int(primary_sj_pos[0])
                    primary_pos2 = int(primary_sj_pos[1])
                    primary_records = None
                    try:
                        primary_records = junc_tb.fetch(region = "%s:%d-%d" % (primary_chr, primary_pos1 - 3, primary_pos2 + 3))
                    except Exception as e:
                        print("%s, %s" % (sjouttab, str(e)))

                    primary_read_count = 0
                    if primary_records is not None:
                        for record_line in primary_records:
                            record = record_line.split('\t')
                            rj_start = int(record[1])
                            rj_end = int(record[2])
                            if primary_pos1 - rj_start == primary_pos2 - rj_end:
                                primary_read_count = int(record[6])

                    hijacked_sj_split = hijacked_sj.split(':')
                    hijacked_chr = hijacked_sj_split[0]
                    hijacked_sj_pos = hijacked_sj_split[1].split('-')
                    hijacked_pos1 = int(hijacked_sj_pos[0])
                    hijacked_pos2 = int(hijacked_sj_pos[1])
                    hijacked_records = None
                    try:
                        region = "%s:%d-%d" % (hijacked_chr, hijacked_pos1 - 3, hijacked_pos2 + 3)
                        hijacked_records = junc_tb.fetch(region = region)
                    except Exception as e:
                        print("%s, %s" % (sjouttab, str(e)))

                    hijacked_read_count = 0
                    if hijacked_records is not None:
                        for record_line in hijacked_records:
                            record = record_line.split('\t')
                            rj_start = int(record[1])
                            rj_end = int(record[2])
                            if hijacked_pos1 - rj_start == hijacked_pos2 - rj_end:
                                hijacked_read_count = int(record[6])
                    
                    total_junction_read_count = hijacked_read_count + primary_read_count
                    alternative_ratio = primary_read_count/(total_junction_read_count + 1)

                    output_obj = {
                        key : value
                        for key, value in csvobj.items()
                        if key not in exclude_output_columns
                    }
                    
                    output_obj["Primary_read_count"] = primary_read_count
                    output_obj["Hijacked_read_count"] = hijacked_read_count
                    output_obj["Total_junction_read_count"] = total_junction_read_count
                    csvobj["Alternative_ratio"] = alternative_ratio
                    csvwriter.writerow(output_obj)

def call_sj_screening(input_files, output_dir, index):
    ret_code = 1
    err_message = ""
    try:
        if index < len(input_files):
            for run in input_files[index]:
                output_file = "%s/%s" % (output_dir, run)
                sj_screening(input_files[index][run], output_file)
        ret_code = 0
    except Exception as e:
        err_message = str(e)
    
    print("End Process (%d): ret_code=%d" % (index, ret_code))
    return (ret_code, err_message)

def main(input_dir, output_dir, processes):

    import glob
    glob_files = {}
    for path in glob.glob(input_dir + "/*"):
        run = path.split(".")[-1]
        if not run in glob_files:
            glob_files[run] = {}
        glob_files[run][path] = None

    input_files = {}
    for i,run in enumerate(sorted(list(glob_files.keys()))):
        mod = i % processes
        if not mod in input_files:
            input_files[mod] = {}
        input_files[mod][run] = sorted(list(glob_files[run].keys()))

    if processes == 1:
        call_sj_screening(input_files, output_dir, 0)
    else:
        import concurrent.futures
        with concurrent.futures.ProcessPoolExecutor(max_workers=processes) as executor:
            features = [executor.submit(call_sj_screening, input_files, output_dir, i) for i in range(processes)]
            for feature in features:
                (ret_code, err_message) = feature.result()
                if ret_code != 0:
                    raise Exception(err_message)

if __name__== "__main__":
    import sys
    input_dir = sys.argv[1]
    output_dir = sys.argv[2]
    processes = int(sys.argv[3])
    main(input_dir, output_dir, processes)

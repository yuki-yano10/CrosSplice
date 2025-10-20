#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def make_gtex_sjouttab_list(path_to_sjouttab, metadata, output_file):
    
    import csv

    sjouttab_sample_dict={}
    with open(path_to_sjouttab) as hin:
        for row in hin:
            file_path = row.rstrip()
            run = file_path.split('/')[-1].split('.')[0]
            sjouttab_sample_dict[run] = file_path

    with open(metadata, 'r') as hin, open(output_file, 'w') as hout:
        csvreader = csv.DictReader(hin, delimiter=',')

        csvwriter = csv.DictWriter(hout, delimiter='\t', lineterminator='\n', fieldnames=[
            "Repository_sample_id", "Run", "Tissue", "Path"
        ])
        csvwriter.writeheader()
        for csvobj in csvreader:
            run = csvobj["Run"]
            gtex_id = csvobj["biospecimen_repository_sample_id"]
            if run in sjouttab_sample_dict:
                file_path = sjouttab_sample_dict.get(run, '-')
                sample_id = "-".join(csvobj["biospecimen_repository_sample_id"].split("-")[0:2])
                tissue = ".".join([csvobj["histological_type"].replace(" ", "_"), csvobj["body_site"].replace(" - ", "-").replace(" (", ".").replace(")", "").replace(" ", "_")])

                csvwriter.writerow({
                    "Repository_sample_id": sample_id,
                    "Run": run,
                    "Tissue": tissue,
                    "Path": file_path
                })
                
if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser()

    parser.add_argument("-path_to_sjouttab", action="store", dest="path_to_sjouttab", help="full path", required=True)
    parser.add_argument("-metadata", action="store", dest="metadata", help="metadata of run", required=True)
    parser.add_argument("-output_file", action="store", dest="output_file", help="output file", required=True)
    o = parser.parse_args()

    make_gtex_sjouttab_list(o.path_to_sjouttab, o.metadata, o.output_file)

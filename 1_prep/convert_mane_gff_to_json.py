#!/usr/bin/env python3

import gzip
import json
import sys

input_gff = sys.argv[1]
output_json = sys.argv[2]

with gzip.open(input_gff, 'rt') as hin:
    gffdata = {}
    for row in hin:
        if row.startswith("#"):
            continue

        F = row.rstrip("\n").split("\t")
        gff_type = F[2]
        if gff_type != "transcript":
            continue

        gff_attributes = F[8]
        id = ""
        tag = ""
        for item in gff_attributes.split(";"):
            (key, value) = item.split("=")
            if key == "ID":
                id = value
            elif key == "tag":
                if 'MANE_Select' in value:
                    tag = 'MANE_Select'
                elif 'MANE_Plus_Clinical' in value:
                    tag = 'MANE_Plus_Clinical'
        if tag != "":
            gffdata[id] = {
                "type": gff_type,
                "tag": tag
            }

with open(output_json, "w") as hout:
    json.dump(gffdata, hout, indent = 2)

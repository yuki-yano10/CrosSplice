#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import math

input_file = sys.argv[1]
output_dir = sys.argv[2]
split_lines = int(sys.argv[3])

os.makedirs(output_dir, exist_ok=True)

header = ""
write_rows = []
file_index = 0
with open(input_file) as hin:
    for row in hin:
        if header == "":
            header = row
            continue
        write_rows.append(row)
        if len(write_rows) % split_lines == 0:
            with open("%s/%d" % (output_dir, file_index), "w") as hout:
                hout.writelines([header] + write_rows)
            file_index += 1
            write_rows = []

if len(write_rows) > 0:
    with open("%s/%d" % (output_dir, file_index), "w") as hout:
        hout.writelines([header] + write_rows)

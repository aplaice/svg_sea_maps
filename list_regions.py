#!/usr/bin/env python3

import json
import sys

lon_0_filter = ""

if len(sys.argv) > 1:
    lon_0_filter = sys.argv[1]

file = open("map_data.json")
map_data = json.load(file)

if lon_0_filter == "":
    for k in map_data.keys():
        print(k)
else:
    for k in map_data.keys():
        if not "lon_0" in map_data[k]:
            map_data[k]["lon_0"] = "0"

        if map_data[k]["lon_0"] == lon_0_filter:
            print(k)

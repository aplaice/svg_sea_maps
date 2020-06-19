#!/usr/bin/env python3

import json
import sys

list_all = False
list_zoomed = True
lon_0_filter = ""

if len(sys.argv) == 1:
    list_all = True
if len(sys.argv) > 1:
    lon_0_filter = sys.argv[1]
if (len(sys.argv) > 2) and (sys.argv[2] == "no_zoom"):
    list_zoomed = False

file = open("map_data.json")
map_data = json.load(file)

if list_all:
    for k in map_data.keys():
        print(k)
else:
    for k in map_data.keys():
        if not "lon_0" in map_data[k]:
            map_data[k]["lon_0"] = "0"

        if not "zoomed" in map_data[k]:
            map_data[k]["zoomed"] = True

        if map_data[k]["lon_0"] == lon_0_filter:
            if (map_data[k]["zoomed"] == list_zoomed):
                print(k)

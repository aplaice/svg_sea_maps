#!/usr/bin/python3

import fiona
import math
import os
import sys

if len(sys.argv) > 1:
    # "shp/upstream/ne_10m_geography_marine_polys.shp"
    input_shp = sys.argv[1]
else:
    sys.exit("Need to specify the input shp.")

relative_dir = '/'.join(input_shp.split("/")[1:-1])
filename = input_shp.split("/")[-1]
output_dir = "shp/densified/" + relative_dir + "/"
# "shp/densified/upstream/ne_10m_geography_marine_polys.shp"
output_shp = output_dir + filename

def distance(p1, p2):
    # this is obviously not any real distance, only the "distance" between points on a WGS84 map
    return math.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2)

def interpolate_after_point(r, i):
    # aim to reduce the distance to about 1
    n = int(distance(r[i], r[i+1]) / 1)
    dx = (r[i+1][0] - r[i][0])/n
    dy = (r[i+1][1] - r[i][1])/n
    for j in range(1, n):
        point = (r[i][0] + j * dx, r[i][1] + j * dy)
        r.insert(i + j, point)
    return (n - 1)

def densify_ring(r):
    distances = []
    i = 0

    # r[0] always equals r[len(r)-1] so we don't need to worry about wrapping round
    # print(r[0], r[len(r)-1])
    while i < (len(r) - 1):
        # arbitrarily let's choose a cut-off of 10
        if distance(r[i], r[i+1]) > 10:
            m = interpolate_after_point(r, i)
            i += m
        i += 1
    
def densify_polygon(p):
    # not sure if ring is the correct terminology
    for ring in p:
        densify_ring(ring)

def densify_feature(feature):
    g = feature["geometry"]
    if g["type"] == "MultiPolygon":
        for polygon in g["coordinates"]:
            densify_polygon(polygon)
    elif g["type"] == "Polygon":
        densify_polygon(g["coordinates"])

if not os.path.isdir(output_dir):
    os.makedirs(output_dir)

with fiona.open(input_shp) as src:

    meta = src.meta

    with fiona.open(output_shp, 'w', encoding='utf-8', **meta) as dst: # test_write.shp

        # # this isn't currently used — all water bodies are densified
        # oceans = ["Arctic Ocean",
        #           "SOUTHERN OCEAN",
        #           "North Atlantic Ocean",
        #           "North Pacific Ocean",
        #           "South Pacific Ocean",
        #           "INDIAN OCEAN",
        #           "South Atlantic Ocean"
        #           ]

        for f in src:
            densify_feature(f)
            dst.write(f)


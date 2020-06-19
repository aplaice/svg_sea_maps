#!/usr/bin/python3

import json
import sys

# could probably use pyshp, but I don't think it's worth it

def polygon(x_0, x_1, y_0, y_1, n):
    """Create a box with the given limits.

There are n points on each edge.

    """
    delta_x = x_1 - x_0
    delta_y = y_1 - y_0
    box_coordinates = []

    for i in range(0, n):
        x = (x_1 - delta_x*i/n)
        y = y_0
        box_coordinates.append([x, y])

    for i in range(0, n):
        x = x_0
        y = y_0 + delta_y*i/n
        box_coordinates.append([x, y])

    for i in range(0, n):
        x = (x_0 + delta_x*i/n)
        y = y_1
        box_coordinates.append([x, y])

    for i in range(0, n):
        x = x_1
        y = y_1 - delta_y*i/n
        box_coordinates.append([x, y])

    return [box_coordinates]

def multipolygon_geojson(l):
    """Return the full geojson for a multipolygon covering the globe

The multipolygon is will work best for a projection
centred on longitude at l.

    """
    epsilon=0.00001
    divisions = 100
    y_max = 89.999
    y_min = -89.999
    x_max = l - epsilon
    x_min = l + epsilon
    # lon_0 = 0
    x_180m = 180
    x_180p = -180


    bounding_box_geometry = {}
    # https://tools.ietf.org/html/rfc7946#section-3.1.9
    bounding_box_geometry["type"] = "MultiPolygon"
    bounding_box_geometry["coordinates"] = [polygon(x_min, x_180m, y_min, y_max, divisions),
                                            polygon(x_180p, x_max, y_min, y_max, divisions)]

    geojson = {"type": "FeatureCollection",
               "features": [{"properties":
                             {"scalerank": 0,
                              "featurecla": "Bounding box centred at longitude of 150"},
                             "type": "Feature",
                             "geometry": bounding_box_geometry}]}

    return geojson

if not len(sys.argv) > 1:
    sys.exit("Need lon_0 to be specified!")

lon_0_s=sys.argv[1]

lon_0=float(lon_0_s)
if lon_0 > 0:
    lon_cut = lon_0 - 180
else:
    lon_cut = lon_0 + 180

with open("shp/intermediate/geojson/%s_centred_bounding_box.geojson" % lon_0_s, "w") as f:
    json.dump(multipolygon_geojson(lon_cut), f)

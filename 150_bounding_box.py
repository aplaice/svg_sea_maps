#!/usr/bin/python3

import json

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

def multipolygon_geojson():
    """Return the full geojson for a multipolygon covering the globe

The multipolygon is pre-configured to work best for a projection
centred on 150° E.

    """
    divisions = 100
    y_max = 89.999
    y_min = -89.999
    x_max = -30.00001
    x_min = -29.99999
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

with open("shp/intermediate/geojson/150_centred_bounding_box.geojson", "w") as f:
    json.dump(multipolygon_geojson(), f)

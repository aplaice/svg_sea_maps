#!/usr/bin/python3

# TODO Make densification follow geodesics (not arbitrary "straight lines" in an equirectangular projection)...
# EXCEPT for parallels (lines of latitude) — in the case of these we DO NOT want geodesics.
# (Lines of longitude are geodesics, so they don't need special treatment.)
# Can probably check for "angle" and for lines within ~ 10° of being a line of latitude use the naïve equirectangular/euclidean interpolation.  (and geodesics for the rest (_possibly_ might not need to interpolate geodesics, as mapshaper's `densify` might work in these cases)).

import fiona
import math
import os
import sys
import numpy as np

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

def is_line_of_latitude(p1, p2):
    """Return true if the line between p1 and p2 is a line of latitude.

    Check "angle" and assume that a line is a line of latitude if the
    angle is less than 10° away from "horizontal"."""

    crit_deg_angle = 2
    crit_rad_angle = crit_deg_angle/180*math.pi
    delta_x = p2[0]-p1[0]
    delta_y = p2[1]-p1[1]
    if delta_x == 0:
        return True
    rad_angle = math.atan(delta_y/delta_x)
    return (abs(rad_angle) < crit_rad_angle)

def interpolate_naively_after_point(r, i):
    # aim to reduce the distance to about 1
    n = int(distance(r[i], r[i+1]) / 1)
    dx = (r[i+1][0] - r[i][0])/n
    dy = (r[i+1][1] - r[i][1])/n
    for j in range(1, n):
        point = (r[i][0] + j * dx, r[i][1] + j * dy)
        r.insert(i + j, point)
    return (n - 1)

def cartesian_coords_from_lon_lat(lon_deg, lat_deg):
    lat = math.pi*lat_deg/180
    lon = math.pi*lon_deg/180
    # r = 1
    x = math.cos(lat) * math.cos(lon)
    y = math.cos(lat) * math.sin(lon)
    z = math.sin(lat)
    return np.array([x, y, z])

def lon_lat_from_cartesian_coords(arr):
    x, y, z = arr
    rho = math.sqrt(x**2 + y**2)
    # ρ is +ve so -pi/2 ≤ lat ≤ pi/2
    lat = math.atan2(z, rho)
    lon = math.atan2(y, x)
    return (lon*180/math.pi, lat*180/math.pi)


def test_lon_lat_conversion():
    for longitude in np.linspace(-180, 180, 500):
        for latitude in np.linspace(-90, 90, 500):
            close = np.all(
                np.isclose(
                    lon_lat_from_cartesian_coords(
                        cartesian_coords_from_lon_lat(
                            longitude, latitude)),
                    (longitude, latitude)))
            if not close:
                print(longitude, latitude)

def interpolate_geodesically_after_point(r, i):
    # Aim to reduce the "distance" to about 1.
    # The number of interpolation points is inherited from the "naïve"
    # version.
    n = int(distance(r[i], r[i+1]) / 1)
    interpolated_points = interpolated_geodesic_points(r[i], r[i+1], n)
    for j, p in zip(range(1,n), interpolated_points):
        point = (p[0], p[1])
        r.insert(i + j, point)
    return (n - 1)

def interpolated_geodesic_points(coords1, coords2, n):
    # We combine r_1, r_2 using:
    # α r_1 + (1-α) r_2
    #
    # This is a lazy approach, as the great-circle angle between
    # consecutive points won't be the same, but at least all the
    # points are guaranteed to be on the great circle!
    (lon1, lat1) = coords1
    (lon2, lat2) = coords2
    alpha = np.linspace(1/n, 1-1/n, n - 2)
    arr1 = cartesian_coords_from_lon_lat(lon1, lat1)
    arr2 = cartesian_coords_from_lon_lat(lon2, lat2)
    np.outer(alpha, arr2) + np.outer(1-alpha, arr1)
    return np.apply_along_axis(
        lon_lat_from_cartesian_coords,
        1,
        np.outer(alpha, arr2) + np.outer(1-alpha, arr1))

def densify_ring(r):
    distances = []
    i = 0

    # r[0] always equals r[len(r)-1] so we don't need to worry about wrapping round
    # print(r[0], r[len(r)-1])
    while i < (len(r) - 1):
        # arbitrarily let's choose a cut-off of 10
        if distance(r[i], r[i+1]) > 10:
            if is_line_of_latitude(r[i], r[i+1]):
                m = interpolate_naively_after_point(r, i)
                i += m
            else:
                m = interpolate_geodesically_after_point(r, i)
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

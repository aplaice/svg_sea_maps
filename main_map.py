#!/usr/bin/env python3

import argparse

from lxml import etree

import os
import sys

import json

from utils import is_interactive, add_interactive_elements

parser = argparse.ArgumentParser(description="Process main map without zooming in or adding a mini-map")
parser.add_argument("sea")
parser.add_argument("lon_0", nargs="?")
parser.add_argument("--interactive", default="yes", const="yes", nargs='?',
                    help="Is the SVG supposed to be interactive?")

args = parser.parse_args()

if not os.path.isfile("map_data.json"):
    sys.exit("Data file does not exist")

with open("map_data.json") as f:
    data = json.load(f)

interactive = is_interactive(args)

if args.sea in data:
    sea_data = data[args.sea]
else:
    sea_data = {}
    if not interactive:
        sys.exit("""There is no point in continuing for a non-interactive map, with a
sea for which there's no existing data.""")

params = [("highlighted_ids", []),
          ("partially_highlighted_ids", []),
          ("lon_0", "0"),
          ("highlight_colour", "#4790c8")]

for param in params:
    if not param[0] in sea_data:
        sea_data[param[0]] = param[1]


if args.lon_0:
    sea_data["lon_0"] = args.lon_0
else:
    sea_data["lon_0"] = "0"

if (not args.lon_0) or (args.lon_0 == "0"):
    input_file = "svg/intermediate/main_map.svg"
    output_directory = "svg/no_zoom/"
else:
    input_file = "svg/intermediate/%s/main_map.svg" % args.lon_0
    output_directory = "svg/no_zoom/%s/" % args.lon_0

output_file = "%s%s.svg" % (output_directory, args.sea)

if not os.path.isdir(output_directory):
    os.makedirs(output_directory)

root = etree.parse(input_file).getroot()
if interactive:
    add_interactive_elements(root, sea_data["lon_0"], args.sea, zoom=False)

def remove_margins(r):
    """Remove the 32-width margins (added in main_map.sh)."""
    r.attrib["width"] = str(int(r.attrib["width"]) - 64)
    r.attrib["height"] = str(int(r.attrib["height"]) - 64)
    r.attrib["viewBox"] = "32 32 %s %s" % (r.attrib["width"], r.attrib["height"])

def thicken_paths(r):
    """Thicken most paths.

(Not those of lakes, which have a default width of 0.75.)
    """
    paths = r.xpath('//svg:path[@stroke-width = 1]',
                    namespaces={"svg": "http://www.w3.org/2000/svg"})

    for p in paths:
        p.attrib["stroke-width"] = "1.5"

def highlight_seas(r, s_data):
    for h_id in s_data["highlighted_ids"]:
        elements = root.xpath(
            '''//*[@id = "{id}"]'''.format(id=h_id),
            namespaces={
                "svg": "http://www.w3.org/2000/svg"
            })
        # should be exactly one element...
        for e in elements:
            e.attrib["fill"] = s_data["highlight_colour"]
            e.attrib["stroke"] = s_data["highlight_colour"]
            # Thicken highlighted sea paths more than land paths (see
            # above). This is necessary, since otherwise, at low zoom,
            # there are gaps visible between elements. (Anti-aliasing issue...)
            e.attrib["stroke-width"] = "8.5"

def hide_other_seas(r):
    """Hide sea paths that are not highlighted.

They can be safely hidden, since the Bounding box is still in the background.

It's useful for them to be hidden, since with the extra-wide strokes of the highlighted seas, and the fact that the order of the highlighted and non-highlighted seas is not fixed (the highlighted seas are neither consistently above or below the non-highlighted seas), weird artefacts form at the edges of the highlighted seas.

Having all the seas have an extra-wide stroke helps only partially with the artefacts, but also results in the seas bulging out at the edges of the globe."""
    # implemented in an imperative manner, to avoid checking whether
    # each ID is in highlighted_ids
    other_sea_paths = r.xpath(
        '//svg:g[@id = "Seas" ]/svg:path[@stroke-width = 1.5]',
        namespaces={"svg": "http://www.w3.org/2000/svg"})
    for p in other_sea_paths:
        p.attrib["fill"] = "none"
        p.attrib["stroke"] = "none"

# # This doesn't help regarding the gaps between elements!
# def make_water_bodies_crisp(r):
#     """Apply shape-rendering="crispEdges" to <g id="Seas">"""
#     g_sea = r.xpath('//svg:g[@id = "Seas" ]',
#                     namespaces={"svg": "http://www.w3.org/2000/svg"})
#     for g in g_sea:
#         # technically should be exactly one element
#         g.attrib["shape-rendering"] = "crispEdges" #"geometricPrecision"

# make_water_bodies_crisp(root)

remove_margins(root)
thicken_paths(root)
highlight_seas(root, sea_data)
hide_other_seas(root)




root.getroottree().write(output_file)

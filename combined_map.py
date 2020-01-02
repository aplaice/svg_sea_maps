#!/usr/bin/env python3

import sys
import os
import json
from lxml import etree

def get_current_sea(args):
    if len(args) > 1:
        return args[1]
    else:
        return False

def get_parameters(args, sea):
    if sea and os.path.isfile("map_data.json"):
        with open("map_data.json", "r") as file:
            map_data = json.load(file)
            if sea in map_data:
                sea_data = map_data[sea]
            else:
                sea_data = {}
    else:
        sea_data = {}

    default_parameters = [("x_offset", 500),
                          ("y_offset", 500),
                          ("width", 1000),
                          ("highlighted_ids", []),
                          ("partially_highlighted_ids", []),
                          # deliberately a string to avoid rounding
                          # issues if lon_0 ever becomes non-integer
                          ("lon_0", "0")]

    for (parameter, default_value) in default_parameters:
        if not parameter in sea_data:
            sea_data[parameter] = default_value
    if len(args) > 2:
        # overwrite lon_0, even if it was set in map_data
        sea_data["lon_0"] = args[2]

    return sea_data

current_sea = get_current_sea(sys.argv)

data = get_parameters(sys.argv, current_sea)



def input_map_filename(map_type, lon_0, current_sea):
    stem = map_type
    if (map_type == "main_map") and (current_sea in ["aral_sea", "celtic_sea", "english_channel", "bering_strait"]):
        stem += "_for_%s" % current_sea

    if lon_0 == "0":
        return "svg/intermediate/%s.svg" % stem
    else:
        return "svg/intermediate/%s/%s.svg" % (lon_0, stem)

def marker_element(width, height, x_offset, y_offset):
    marker_g = etree.Element("g")
    marker_g.attrib["id"] = "Marker"

    marker_opacity = etree.SubElement(marker_g, "rect")
    marker_box = etree.SubElement(marker_g, "rect")

    for marker in [marker_opacity, marker_box]:
        for attrib, size in [("width", width),
                             ("height", height),
                             ("x", x_offset),
                             ("y", y_offset)]:
            # width of mini_map globe is 1/32 that of the main globe
            marker.attrib[attrib] = str(size / 32)

    marker_opacity.attrib["fill"] = "#C02637"
    marker_opacity.attrib["opacity"] = "0.1"

    marker_box.attrib["stroke"] = "#C02637"
    marker_box.attrib["stroke-width"] = "0.5"
    marker_box.attrib["fill"] = "none"

    return marker_g

def pattern_definitions_element():
    "Create an element containing the hatch pattern defintion"
    # https://stackoverflow.com/questions/13069446/simple-fill-pattern-in-svg-diagonal-hatching

    defs = etree.Element("defs")

    pattern = etree.SubElement(defs, "pattern")
    pattern.attrib["id"] = "hatchPattern"
    pattern.attrib["width"] = "4"
    pattern.attrib["height"] = "4"
    pattern.attrib["patternTransform"] = "rotate(45)"
    pattern.attrib["patternUnits"] = "userSpaceOnUse"

    line = etree.SubElement(pattern, "line")
    line.attrib["x1"] = "2"
    line.attrib["y1"] = "0"
    line.attrib["x2"] = "2"
    line.attrib["y2"] = "4"
    line.attrib["stroke"] = "#4790c8"
    line.attrib["stroke-width"] = "1.5"

    return defs

class CombineSVGs:

    # main_globe_width = 4000
    # main_globe_height = 2469

    # nice 16:9 ratio
    svg_height = 281.25
    svg_width = 500

    def __init__(self, sea_data, current_sea):
        self.width = sea_data["width"]
        self.x_offset = sea_data["x_offset"]
        self.y_offset = sea_data["y_offset"]
        self.highlighted_ids = sea_data["highlighted_ids"]
        self.partially_highlighted_ids = sea_data["partially_highlighted_ids"]
        self.lon_0 = sea_data["lon_0"]

        self.height = self.width * 9/16

        self.current_sea = current_sea

        # svg_height = height/width * svg_width
        self.main_map_scale = self.svg_width / self.width

    def create_main_map(self):
        main_map_file = input_map_filename("main_map", self.lon_0, self.current_sea)
        self.main_map = etree.parse(main_map_file)

        self.main_map_g = etree.Element("g")
        self.main_map_g.attrib["id"] = "Main_map"
        for child in self.main_map.getroot().getchildren():
            self.main_map_g.append(child)

    def style_main_map(self):
        self.main_map_g.attrib["transform"] = "scale({s}) translate({x} {y})".format(
            x=-self.x_offset,
            y=-self.y_offset,
            s=self.svg_width / self.width)

        for h_id in self.highlighted_ids:
            elements = self.main_map_g.xpath(
                '''//*[@id = "{id}"]'''.format(id=h_id),
                namespaces={
                    "svg": "http://www.w3.org/2000/svg"
                })
            # should be exactly one element...
            for e in elements:
                e.attrib["fill"] = "#4790c8"
                e.attrib["stroke"] = "#4790c8"

        for ph_id in self.partially_highlighted_ids:
            elements = self.main_map_g.xpath(
                '''//*[@id = "{id}"]'''.format(id=ph_id),
                namespaces={
                    "svg": "http://www.w3.org/2000/svg"
                })
            # should be exactly one element...
            for e in elements:
                e.attrib["fill"] = "url(#hatchPattern)"
                e.attrib["stroke"] = "#4790c8"

    def create_mini_map(self):
        mini_map_file = input_map_filename("mini_map", self.lon_0, self.current_sea)
        mini_map = etree.parse(mini_map_file)

        self.mini_map_g = etree.Element("g")
        self.mini_map_g.attrib["id"] = "Mini_map"
        for child in mini_map.getroot().getchildren():
            self.mini_map_g.append(child)

    def style_mini_map(self):
        self.mini_map_g.attrib["transform"] = "translate({x} {y}) scale({s})".format(
            x=5,
            # height of mini_map globe is 77
            y=self.svg_height - 5 - (77 * self.svg_width/125 * 0.28),
            # width of mini_map globe is 125
            # the mini_map should take up 0.28 of the width of the visible map
            s=self.svg_width/125 * 0.28)

        self.mini_map_g.append(marker_element(self.width, self.height, self.x_offset, self.y_offset))

        # If we don't need to zoom in, the following gives a nice result:

        # mini_map_g.attrib["transform"] = "translate({x} {y}) scale({s} {s})".format(
        #     x = 50,
        #     y = 1700,
        #     # width of mini_map globe is 1/32 that of the main globe
        #     # the mini_map should take up 0.28 of the width of the visible map
        #     s = 0.28 * 32 )

    def prepare_root(self):
        self.create_main_map()
        self.style_main_map()
        self.create_mini_map()
        self.style_mini_map()

        self.root = self.main_map.getroot()

        self.root.append(self.main_map_g)
        self.root.append(self.mini_map_g)

        if self.partially_highlighted_ids:
            self.root.insert(0, pattern_definitions_element())

        self.root.attrib["width"] = str(self.svg_width)
        self.root.attrib["height"] = str(self.svg_height)
        self.root.attrib["viewBox"] = "0 0 {w} {h}".format(
            w=self.svg_width,
            h=self.svg_height)

    def add_interactive_elements(self):
        if self.lon_0 == "0":
            controls_directory = "../"
        else:
            controls_directory = "../../"

        self.root.attrib["data-current-sea"] = self.current_sea
        self.root.attrib["data-lon_0"] = self.lon_0
        # id="script_tag" type="text/javascript" xlink:href="controls.js
        # xmlns:xlink="http://www.w3.org/1999/xlink"
        script_element = etree.SubElement(self.root, "script")
        script_element.attrib["id"] = "script_tag"
        script_element.attrib["type"] = "text/javascript"
        script_element.attrib["{http://www.w3.org/1999/xlink}href"] = controls_directory + "controls.js"

    def write_output(self):
        if self.lon_0 == "0":
            target_directory = "svg/"
        else:
            target_directory = "svg/%s/" % self.lon_0

        if not os.path.isdir(target_directory):
            os.makedirs(target_directory, exist_ok=True)

        if self.current_sea:
            output_filename = self.current_sea.replace(" ", "_") + ".svg"
        else:
            output_filename = "combined_map.svg"

        self.main_map.write(target_directory + output_filename)


interactive = True and current_sea

combine = CombineSVGs(data, current_sea)
combine.prepare_root()
if interactive:
    combine.add_interactive_elements()

combine.write_output()
    


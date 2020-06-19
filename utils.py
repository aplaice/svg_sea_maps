from lxml import etree

def is_interactive(args):
    """Assume the SVG is to be interactive unless explicitly stated otherwise.
    """
    if args.interactive == "no":
        return False
    else:
        return True

def add_interactive_elements(root, lon_0, current_sea, zoom=True):
        if lon_0 == "0":
            controls_directory = "../"
        else:
            controls_directory = "../../"
        if not zoom:
            controls_directory += "../"

        root.attrib["data-current-sea"] = current_sea
        root.attrib["data-lon_0"] = lon_0
        if not zoom:
            root.attrib["data-not-zoomed"] = ""

        # id="script_tag" type="text/javascript" xlink:href="controls.js
        # xmlns:xlink="http://www.w3.org/1999/xlink"
        script_element = etree.SubElement(root, "script")
        script_element.attrib["id"] = "script_tag"
        script_element.attrib["type"] = "text/javascript"
        script_element.attrib["{http://www.w3.org/1999/xlink}href"] = controls_directory + "controls.js"

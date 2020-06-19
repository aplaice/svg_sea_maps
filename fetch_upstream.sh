#!/bin/bash

function build_upstream_url() {
    local scale="$(echo "$1" | sed 's/ne_\([0-9]*m\)_.*/\1/')"
    local stem="$(echo "$1" | sed 's/ne_[^_]*_\([^\.]*\).shp/\1/')"
    local category
    case $stem in
	(admin_0_boundary_lines_disputed_areas | admin_0_boundary_lines_land | admin_0_countries_lakes)
	    category="cultural"
	    ;;
	(geography_marine_polys | lakes_historic | lakes | wgs84_bounding_box | geography_regions_polys | land)
	    category="physical"
	    ;;
    esac
    local url_base="https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/"
    local url="${url_base}${scale}/${category}/ne_${scale}_${stem}.zip"
    if [ x"$stem" == x"" ] || [ x"$scale" == x"" ] || [ x"$category" == x"" ]
    then
	exit 1
    fi
    echo "$url"
}

mkdir -p shp/upstream/
shp_target="${1#shp/upstream/}"
upstream_url=$(build_upstream_url "$shp_target")
if [ ! x"$upstream_url" == x"" ]
then
    cd shp/upstream/
    wget "$upstream_url"
    unzip "${shp_target/%.shp/.zip}"
else
    echo "Invalid shp file!"
fi

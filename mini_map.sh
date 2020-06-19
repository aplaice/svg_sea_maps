#!/bin/bash

if [ x"$1" == x ]
then
    ocean_shapefile=shp/upstream/ne_10m_wgs84_bounding_box.shp
    continents_shapefile=shp/upstream/ne_110m_land.shp
    mini_map_bounding_box_shapefile="$ocean_shapefile"

    output_svg="svg/intermediate/mini_map.svg"

    declare -a mapshaper_projection=(-proj '+proj=wintri +lon_0=0' 'target=*')
    # lon_0=0
elif [ x"$1" == x"150" ]
then
    ocean_shapefile=shp/misc/150_centred_bounding_box.shp
    continents_shapefile=shp/recut/150/upstream/ne_110m_land.shp
    mini_map_bounding_box_shapefile="$ocean_shapefile"

    output_svg="svg/intermediate/150/mini_map.svg"

    declare -a mapshaper_projection=(-proj '+proj=wintri +lon_0=150' 'target=*')
    # lon_0=150
else
    echo "lon_0 other than 0 and 150 is not supported for mini-maps, yet"
    # it shouldn't be hard though
    exit 1
fi

mkdir -p "$(dirname "$output_svg")"

./node_modules/mapshaper/bin/mapshaper \
    -i "$ocean_shapefile" 'name=Ocean' \
    -i "$continents_shapefile" 'name=Continents' \
    -i "$mini_map_bounding_box_shapefile" 'name=Mini_map_bounding_box' \
    "${mapshaper_projection[@]}" \
    -style 'target=Ocean' 'fill=#F8F9FA' \
    -style 'target=Continents' 'fill=#CECECE' \
    -style 'target=Mini_map_bounding_box' 'fill=none' 'stroke-width=1' 'stroke=#646565' \
    -clean \
    -o 'target=*' 'width=125' "$output_svg"


# 0.28 width of mini-map compared to main map



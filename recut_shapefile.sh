#!/bin/bash

if [ x"$1" == x ]
then
    echo "Need to select shapefile"
    exit 1
fi
if [ x"$2" == x"" ]
then
    echo "Need to specify lon_0 (new central meridian)."
    exit 1
fi

lon_0="$2"

d3_rotation=$(bc <<<"360 - $lon_0")
cut_longitude=$(bc <<<"if ( $lon_0 > 0 ) $lon_0 - 180 else $lon_0 + 180")
east_cut=$(bc <<<"$cut_longitude + 0.01")
west_cut=$(bc <<<"$cut_longitude - 0.01")
east_bbox="${east_cut},-90,180,90"
west_bbox="-180,-90,${west_cut},90"

cut_geojson=shp/intermediate/geojson/cut/"$1".geojson
uncut_geojson=shp/intermediate/geojson/uncut/"$1".geojson
# these obviously aren't quite the western and eastern hemispheres
western_hemisphere_shapefile=shp/intermediate/cut/"$1"_1.shp
eastern_hemisphere_shapefile=shp/intermediate/cut/"$1"_2.shp

recut_shapefile=shp/recut/"$lon_0"/"$1".shp

if [ x"$3" == x"use_geoproject_intermediate" ]
then
    use_geoproject_intermediate=yes
    recut_shapefile=shp/projected_w3/"$lon_0"/"$1".shp
fi

for file in "$cut_geojson" "$uncut_geojson" "$western_hemisphere_shapefile" "$eastern_hemisphere_shapefile" "$recut_shapefile"
do
    mkdir -p "$(dirname "$file")"
done

if [ -v use_geoproject_intermediate ]
then
    ./node_modules/mapshaper/bin/mapshaper -i shp/"$1".shp 'encoding=utf-8' \
					   -o "$cut_geojson"

    ./node_modules/d3-geo-projection/bin/geostitch < "$cut_geojson" |
	./node_modules/d3-geo-projection/bin/geoproject 'd3.geoWinkel3().rotate(['"$d3_rotation"']).precision(0.1)' |
	./node_modules/d3-geo-projection/bin/geoproject 'd3.geoIdentity().reflectY(true)' > "$uncut_geojson"
    # could also consider just doing a geoIdentity that rotates by 150 ° (if such exists) and then doing a Winkel III projection in main_map, as before

    ./node_modules/mapshaper/bin/mapshaper -i "$uncut_geojson" 'encoding=utf-8' \
					   -o "$recut_shapefile"

else

    ./node_modules/mapshaper/bin/mapshaper -i shp/"$1".shp 'encoding=utf-8' \
					   -clip 'bbox='"$east_bbox" \
					   -o "$eastern_hemisphere_shapefile"

    # in case the same name/ADMIN is present in both parts of the map we
    # need to disambiguate in order to end up with unique IDs
    ./node_modules/mapshaper/bin/mapshaper -i shp/"$1".shp 'encoding=utf-8' \
					   -clip 'bbox='"$west_bbox" \
					   -each 'if ("ADMIN" in this.properties) { ADMIN += "_western_hemisphere"; }' \
					   -each 'if ("name" in this.properties) { name += "_western_hemisphere"; }' \
					   -o "$western_hemisphere_shapefile"

    ./node_modules/mapshaper/bin/mapshaper -i "$eastern_hemisphere_shapefile" \
					   "$western_hemisphere_shapefile" \
					   combine-files 'encoding=utf-8' \
					   -merge-layers \
					   -o "$recut_shapefile"
fi


# 				       # -each 'if ("name" in this.properties) { ADMIN=name ; }'
# 				       # -dissolve ADMIN
# -dissolve scalerank,featurecla,min_zoom,id
# 				       # -clean

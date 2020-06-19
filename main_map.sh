#!/bin/bash

declare -A shps
shps[bounding_box]=upstream/ne_10m_wgs84_bounding_box.shp
shps[seas]=densified/upstream/ne_10m_geography_marine_polys.shp
shps[countries]=upstream/ne_50m_admin_0_countries_lakes.shp

shps[lakes]=simplified/ne_10m_lakes.shp

shps[borders]=upstream/ne_50m_admin_0_boundary_lines_land.shp
# Use the 50m version, as the 10m has a wonky Western Sahara border
# resulting in an ugly dashed line.  Using a slightly less precise
# version for disputed borders (already "fuzzy") should be OK.
shps[disputed_borders]=upstream/ne_50m_admin_0_boundary_lines_disputed_areas.shp
shps[coastline]=dissolved/ne_50m_land.shp

function prefix_shps_array() {
    # I'm not sure if it's possible to return an associative array in
    # a nice way, which would be the better approach.
    prefix="$1"
    for key in "${!shps[@]}"
    do
	shps[$key]="${prefix}${shps[$key]}"
    done
}

if [ x"$1" == x ] || [ x"$1" == x0 ]
then
    prefix_shps_array "shp/"

    output_svg="svg/intermediate/main_map.svg"

    declare -a mapshaper_projection=(-proj '+proj=wintri +lon_0=0' densify 'target=*')
    # lon_0=0

    countries_min_slivers=100000000

    declare -a clip_countries_to_coastline_p=(-clip 'target=Countries' 'source=Coastline')
elif [ x"$1" == x"150" ]
then
    shps[bounding_box]=misc/150_centred_bounding_box.shp

    prefix_shps_array "shp/projected_w3/150/"

    output_svg="svg/intermediate/150/main_map.svg"

    # we use geoproject's projection instead of mapshaper's
    declare -a mapshaper_projection=()
    # lon_0=150

    countries_min_slivers=0.01

    declare -a clip_countries_to_coastline_p=()
else
    lon_0="$1"
    shps[bounding_box]=misc/"$lon_0"_centred_bounding_box.shp

    prefix_shps_array "shp/projected_w3/"$lon_0"/"

    output_svg="svg/intermediate/$lon_0/main_map.svg"

    # we use geoproject's projection instead of mapshaper's
    declare -a mapshaper_projection=()

    countries_min_slivers=0.01

    declare -a clip_countries_to_coastline_p=()
fi

if [ x"$2" == x ]
then
    declare -a extra_land_options=()
elif [ x"$2" == xaral_sea ]
then
    declare -a extra_land_options=(-i "shp/upstream/ne_10m_lakes_historic.shp" 'encoding=utf-8' \
				      'name=Historic_lakes' \
				      -style 'stroke=none' 'stroke-width=0.75' 'fill=none' \
				      -each 'name=name.replace(/ /g, "_")' \
				      -each 'name+="_historic"')
    # -style 'stroke=#1178AC' 'stroke-width=0.75' 'fill=#B3DFF5'
    # -style 'stroke=none' 'stroke-width=0.75' 'fill=none'
    output_svg="${output_svg/%.svg/_for_aral_sea.svg}"
elif [ x"$2" == xceltic_sea ]
then
    # these have to be under (before) countries, so can't re-use the aral_sea_... variable
    declare -a pangaea_sea_optional_options=(-i "shp/from_kml/Celtic_Sea.shp" 'encoding=utf-8' \
						'name=Pangaea_sea_holder' \
						-style 'stroke=none' 'stroke-width=1' 'fill=none' \
						-each 'name="Celtic_Sea"')

    output_svg="${output_svg/%.svg/_for_celtic_sea.svg}"
elif [ x"$2" == xenglish_channel ]
then
    declare -a pangaea_sea_optional_options=(-i "shp/from_kml/English_Channel.shp" 'encoding=utf-8' \
						'name=Pangaea_sea_holder' \
						-style 'stroke=none' 'stroke-width=1' 'fill=none' \
						-each 'name="English_Channel_-_pangaea"')

    output_svg="${output_svg/%.svg/_for_english_channel.svg}"
elif [ x"$2" == xbanda_sea ]
then
    declare -a pangaea_sea_optional_options=(-i "shp/projected_w3/150/from_kml/Banda_Sea.shp" 'encoding=utf-8' \
						'name=Pangaea_sea_holder' \
						-style 'stroke=none' 'stroke-width=1' 'fill=none' \
						-each 'name="Banda_Sea_-_pangaea"')

    output_svg="${output_svg/%.svg/_for_banda_sea.svg}"
elif [ x"$2" == xbering_strait ]
then
    # not actually using data from pangaea, but the option can be
    # re-used since the sea needs to be "over" the normal seas, but
    # still "below" normal land
    declare -a pangaea_sea_optional_options=(-i "shp/projected_w3/150/original/bering_strait.shp" 'encoding=utf-8' \
						'name=Bering_Strait_holder' \
						-style 'stroke=none' 'stroke-width=1' 'fill=none' )

    output_svg="${output_svg/%.svg/_for_bering_strait.svg}"
elif [ x"$2" == xbalkan_peninsula ]
then
    declare -a extra_land_options=(-i "shp/upstream/ne_50m_geography_regions_polys.shp" 'encoding=utf-8' \
				      'name=Peninsulas' \
				      -style 'stroke=none' 'stroke-width=0.5' 'fill=none' \
				      -each 'name=name.replace(/ /g, "_")' \
				      -each 'name=name.toLowerCase()' \
				      -filter 'featurecla == "Pen/cape"' -filter 'scalerank <= 2' )
    declare -a clip_extra_land_land=( -clip 'target=Peninsulas' 'source=Coastline' )
    output_svg="${output_svg/%.svg/_for_balkan_peninsula.svg}"
    # use aral_sea_optional_options (and rename (perhaps extra_land_...); also rename pangaea_sea_optional_options)
elif [ x"$2" == xsumatra ]
then
    declare -a extra_land_options=(-i "shp/projected_w3/150/upstream/ne_50m_geography_regions_polys.shp" 'encoding=utf-8' \
				      'name=Islands' \
				      -style 'stroke=none' 'stroke-width=0' 'fill=none' \
				      -each 'name=name.replace(/ /g, "_")' \
				      -each 'name=name.toLowerCase()' \
				      -filter 'featurecla == "Island"' \
				      -simplify '20%')
    declare -a clip_extra_land_land=( -clip 'target=Islands' 'source=Coastline' )
    output_svg="${output_svg/%.svg/_for_sumatra.svg}"
    # output_svg="$(echo "$output_svg" | sed 's/.svg/_for_'"$2"'.svg/')"
fi


mkdir -p "$(dirname "$output_svg")"

./node_modules/mapshaper/bin/mapshaper \
    -i "${shps[bounding_box]}" 'encoding=utf-8' 'name=Bounding_box' \
    -i "${shps[seas]}" 'encoding=utf-8' 'name=Seas' snap \
    "${pangaea_sea_optional_options[@]}" \
    -i "${shps[countries]}" 'encoding=utf-8' 'name=Countries' \
    "${extra_land_options[@]}" \
    -i "${shps[lakes]}" 'encoding=utf-8' 'name=Lakes' \
    -i "${shps[borders]}" 'encoding=utf-8' 'name=Borders' \
    -i "${shps[disputed_borders]}" 'encoding=utf-8' 'name=Disputed_borders_1' \
    -i "${shps[coastline]}" 'encoding=utf-8' 'name=Coastline' \
    "${mapshaper_projection[@]}" \
    -filter 'target=Borders' 'featurecla != "Overlay limit"' \
    -filter 'target=Borders' 'featurecla != "Lease limit"' \
    -filter 'target=Borders' \
    '!((featurecla == "International boundary (verify)") || (featurecla == "Indefinite (please verify)"))' \
    '+' 'name=Disputed_borders_2' \
    -filter 'target=Borders' \
    '(featurecla == "International boundary (verify)") || (featurecla == "Indefinite (please verify)")' \
    -merge-layers 'target=Disputed_borders_1,Disputed_borders_2' 'name=Disputed_borders' force \
    -style 'target=Bounding_box' 'fill=#B3DFF5' \
    -style 'target=Countries' 'fill=#FDFBE5' \
    -style 'target=Seas' 'fill=#B3DFF5' 'stroke=#B3DFF5' 'stroke-width=1' \
    -style 'target=Lakes' 'stroke=#1178AC' 'stroke-width=0.75' 'fill=#B3DFF5' \
    -style 'target=Borders' 'stroke=#656565' 'stroke-width=1' \
    -style 'target=Disputed_borders' 'stroke=#656565' 'stroke-width=1' 'stroke-dasharray=""2,2""' \
    -style 'target=Coastline' 'stroke=#1178AC' 'stroke-width=1' 'fill=none' \
    -filter-slivers 'target=Countries' "min-area=$countries_min_slivers" \
    `# clipping Country to Coastline for lon_0=150 causes Western Hemisphere mainland Russia to disappear` \
    `# arguably could just remove this clipping, as its lack doesn't seem to cause any visible artifacts` \
    "${clip_countries_to_coastline_p[@]}" \
    "${clip_extra_land_land[@]}" \
    -clip 'target=Borders' 'source=Coastline' \
    -clip 'target=Disputed_borders' 'source=Coastline' \
    `# fine-tuning for nameless sea areas to get unique ids` \
    -each 'target=Seas' 'if (name === "") { name = "_" + note + "_" + ne_id; }' \
    `# remove whitespace from names` \
    -each 'target=Countries' 'ADMIN=ADMIN.replace(/ /g, "_")' \
    -each 'target=Seas' 'name=name.replace(/ /g, "_")' \
    -each 'target=Lakes' 'name=name.replace(/ /g, "_")' \
    `# borders don't really need names (and want to avoid duplicate "Line of control")` \
    -each 'target=Disputed_borders' 'delete name' \
    `# fine-tuning to avoid duplicate ids` \
    -each 'target=Seas' 'if (["Ross_Sea", "Mediterranean_Sea"].includes(name)) { name+= "_" + ne_id; }' \
    -each 'target=Lakes' 'if (["Grand_Lake", "Trout_Lake", "Dead_Sea", "Ozero_Mogotoyevo"].includes(name)) { name+= "_" + ne_id; }' \
    -o 'target=*' 'width=4000' 'margin=32' 'id-field=name,ADMIN' "$output_svg"


#				       -simplify '10%' \

# I don't know what's special about mapshaper's own encoding output that I need to specify
# encoding=utf-8
# when inputting that output back in...

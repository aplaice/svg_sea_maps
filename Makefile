MS = ./node_modules/mapshaper/bin/mapshaper

# Is the SVG supposed to be interactive (load controls.js)?
INTERACTIVE ?= yes

MAIN_MAP_SHAPEFILES ::= shp/simplified/ne_10m_lakes.shp \
shp/densified/upstream/ne_10m_geography_marine_polys.shp \
shp/upstream/ne_50m_admin_0_countries_lakes.shp \
shp/upstream/ne_50m_admin_0_boundary_lines_land.shp \
shp/upstream/ne_50m_admin_0_boundary_lines_disputed_areas.shp \
shp/dissolved/ne_50m_land.shp

MAIN_MAP_0_SHAPEFILES ::= $(MAIN_MAP_SHAPEFILES) shp/upstream/ne_10m_wgs84_bounding_box.shp

MINI_MAP_0_SHAPEFILES ::= shp/upstream/ne_110m_land.shp \
shp/upstream/ne_10m_wgs84_bounding_box.shp

MAIN_MAP_150_SHAPEFILES ::= $(MAIN_MAP_SHAPEFILES) shp/misc/150_centred_bounding_box.shp
MAIN_MAP_150_SHAPEFILES ::= $(patsubst shp/%,shp/projected_w3/150/%, $(MAIN_MAP_150_SHAPEFILES))

MINI_MAP_150_SHAPEFILES ::= shp/recut/150/upstream/ne_110m_land.shp \
shp/misc/150_centred_bounding_box.shp

MAIN_MAP_11.5_SHAPEFILES ::= $(MAIN_MAP_SHAPEFILES) shp/misc/11.5_centred_bounding_box.shp
MAIN_MAP_11.5_SHAPEFILES ::= $(patsubst shp/%,shp/projected_w3/11.5/%, $(MAIN_MAP_11.5_SHAPEFILES))

COMBINED_MAP_SCRIPT ::= combined_map.py utils.py

shp/upstream/%.shp:
	./fetch_upstream.sh "$@"

shp/from_kml/%.shp:
	./fetch_pangaea.sh

shp/simplified/ne_10m_lakes.shp: shp/upstream/ne_10m_lakes.shp
	mkdir -p shp/simplified/
	$(MS) "$<" -simplify '10%' -filter 'scalerank <= 5' -o "$@"

shp/dissolved/ne_50m_land.shp: shp/upstream/ne_50m_land.shp
	mkdir -p shp/dissolved/
	$(MS) "$<" -each 'id = this.id; if (id === 137) { id = 1380 ; } if (id === 60) { id = 1379 ; min_zoom = 0.5 ;}' \
	-dissolve scalerank,featurecla,min_zoom,id \
	-o "$@"

shp/densified/upstream/ne_10m_geography_marine_polys.shp: shp/upstream/ne_10m_geography_marine_polys.shp densify_water_bodies.py
	./densify_water_bodies.py "$<"

# we can't use the "clip boxes" method of recutting, (see below) as it
# can't merge/dissolve East Siberia correctly. (However much
# dissolving and cleaning one does, the border at the anti-meridian
# still remains.)
shp/projected_w3/150/%.shp: shp/%.shp recut_shapefile.sh
	./recut_shapefile.sh "$*" 150 use_geoproject_intermediate 

shp/projected_w3/11.5/%.shp: shp/%.shp recut_shapefile.sh
	./recut_shapefile.sh "$*" 11.5 use_geoproject_intermediate 

# # e.g. shp/projected_w3/150/upstream/sea.shp:
# shp/projected_w3/%.shp: shp/%.shp recut_shapefile.sh
# 	./recut_shapefile.sh "$(*F)" "$(*D)" use_geoproject_intermediate 

# do not use geostitch and geoproject for ne_110m_land (used for the
# mini-map) as the reflectY(true) step causes the Caspian Sea to
# disappear.
shp/recut/150/%.shp: shp/%.shp recut_shapefile.sh
	./recut_shapefile.sh "$*" 150

shp/recut/11.5/%.shp: shp/%.shp recut_shapefile.sh
	./recut_shapefile.sh "$*" 11.5

# # e.g. shp/recut/150/upstream/sea.shp
# shp/recut/%.shp: shp/%.shp recut_shapefile.sh
# 	./recut_shapefile.sh "$(*F)" "$(*D)"

shp/misc/%_centred_bounding_box.shp: shp/upstream/ne_10m_wgs84_bounding_box.shp shifted_bounding_box.py
	mkdir -p shp/misc/ shp/intermediate/geojson/
	./shifted_bounding_box.py $*
	$(MS) "shp/intermediate/geojson/$*_centred_bounding_box.geojson" -o "$@"

svg/intermediate/main_map.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES)
	./main_map.sh

svg/intermediate/mini_map.svg: mini_map.sh $(MINI_MAP_0_SHAPEFILES)
	./mini_map.sh


svg/intermediate/150/main_map.svg: main_map.sh $(MAIN_MAP_150_SHAPEFILES)
	./main_map.sh 150

svg/intermediate/11.5/main_map.svg: main_map.sh $(MAIN_MAP_11.5_SHAPEFILES)
	./main_map.sh 11.5

# .SECONDEXPANSION:
# svg/intermediate/%/main_map.svg: main_map.sh $$(MAIN_MAP_$$*_SHAPEFILES)
# 	./main_map.sh $(*)

svg/intermediate/150/mini_map.svg: mini_map.sh $(MINI_MAP_150_SHAPEFILES)
	./mini_map.sh 150

svg/intermediate/main_map_for_aral_sea.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/upstream/ne_10m_lakes_historic.shp
	./main_map.sh 0 aral_sea

svg/intermediate/main_map_for_celtic_sea.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/from_kml/Celtic_Sea.shp
	./main_map.sh 0 celtic_sea

svg/intermediate/main_map_for_english_channel.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/from_kml/English_Channel.shp
	./main_map.sh 0 english_channel

svg/intermediate/main_map_for_baltic_sea.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/from_kml/Baltic_Sea.shp
	./main_map.sh 0 baltic_sea

svg/intermediate/main_map_for_gulf_of_california.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/from_kml/Gulf_of_California.shp
	./main_map.sh 0 gulf_of_california

svg/intermediate/main_map_for_white_sea.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/from_kml/White_Sea.shp
	./main_map.sh 0 white_sea

svg/intermediate/150/main_map_for_banda_sea.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/projected_w3/150/from_kml/Banda_Sea.shp
	./main_map.sh 150 banda_sea

svg/intermediate/150/main_map_for_gulf_of_carpentaria.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/projected_w3/150/from_kml/Gulf_of_Carpentaria.shp
	./main_map.sh 150 gulf_of_carpentaria

svg/intermediate/150/main_map_for_bering_strait.svg: main_map.sh $(MAIN_MAP_150_SHAPEFILES) shp/projected_w3/150/original/bering_strait.shp
	./main_map.sh 150 bering_strait

svg/intermediate/main_map_for_balkan_peninsula.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/upstream/ne_50m_geography_regions_polys.shp
	./main_map.sh 0 balkan_peninsula

svg/intermediate/150/main_map_for_sumatra.svg: main_map.sh $(MAIN_MAP_150_SHAPEFILES) shp/projected_w3/150/upstream/ne_50m_geography_regions_polys.shp
	./main_map.sh 150 sumatra

svg/combined_map.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map.svg
	./combined_map.py

svg/150/%.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/150/mini_map.svg svg/intermediate/150/main_map.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" $* 150

svg/%.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" $*

svg/aral_sea.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map_for_aral_sea.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" aral_sea

svg/celtic_sea.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map_for_celtic_sea.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" celtic_sea

svg/english_channel.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map_for_english_channel.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" english_channel

svg/baltic_sea.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map_for_baltic_sea.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" baltic_sea

svg/gulf_of_california.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map_for_gulf_of_california.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" gulf_of_california

svg/white_sea.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map_for_white_sea.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" white_sea

svg/150/banda_sea.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/150/mini_map.svg svg/intermediate/150/main_map_for_banda_sea.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" banda_sea 150

svg/150/gulf_of_carpentaria.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/150/mini_map.svg svg/intermediate/150/main_map_for_gulf_of_carpentaria.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" gulf_of_carpentaria 150

svg/150/bering_strait.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/150/mini_map.svg svg/intermediate/150/main_map_for_bering_strait.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" bering_strait 150

svg/balkan_peninsula.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map_for_balkan_peninsula.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" balkan_peninsula 0

svg/150/sumatra.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/150/mini_map.svg svg/intermediate/150/main_map_for_sumatra.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" sumatra 150

# svg/no_zoom/%.svg: main_map.py utils.py svg/intermediate/main_map.svg map_data.json
# 	./main_map.py --interactive="$(INTERACTIVE)" $*

svg/no_zoom/150/%.svg: main_map.py utils.py svg/intermediate/150/main_map.svg map_data.json
	./main_map.py --interactive="$(INTERACTIVE)" $* 150

svg/no_zoom/11.5/%.svg: main_map.py utils.py svg/intermediate/11.5/main_map.svg map_data.json
	./main_map.py --interactive="$(INTERACTIVE)" $* 11.5


# When making PNGs the SVGs are considered intermediate files.
# Normally, make would delete them after making the PNGs. To avoid
# that mark them as ".PRECIOUS"
# Ditto for SHP files.
.PRECIOUS: svg/%.svg svg/150/%.svg svg/no_zoom/11.5/%.svg svg/no_zoom/150/%.svg shp/upstream/%.shp shp/from_kml/%.shp

# not implemented yet
%_interactive.svg: $(COMBINED_MAP_SCRIPT) svg/intermediate/mini_map.svg svg/intermediate/main_map.svg map_data.json
	./combined_map.py $* interactive

png/ug-map-%.png: svg/%.svg
	mkdir -p png/
	inkscape "$<" --export-png="$@" -w 500
	optipng "$@"

png/150/ug-map-%.png: svg/150/%.svg
	mkdir -p png/150/
	inkscape "$<" --export-png="$@" -w 500
	optipng "$@"

png/no_zoom/ug-map-%-nobox.png: svg/no_zoom/%.svg
	mkdir -p png/no_zoom/
	inkscape "$<" --export-png="$@" -w 500
	optipng "$@"

png/no_zoom/150/ug-map-%-nobox.png: svg/no_zoom/150/%.svg
	mkdir -p png/no_zoom/150/
	inkscape "$<" --export-png="$@" -w 500
	optipng "$@"

png/no_zoom/11.5/ug-map-%-nobox.png: svg/no_zoom/11.5/%.svg
	mkdir -p png/no_zoom/11.5/
	inkscape "$<" --export-png="$@" -w 500
	optipng "$@"

.PHONY: all_0_svgs all_0_pngs all_150_svgs all_150_pngs all_tests install clean_shp

install:
	npm install mapshaper@0.5.5 d3-geo-projection

all_0_svgs:
	./list_regions.py 0 | xargs -I '{}' make svg/'{}'.svg

all_0_pngs:
	./list_regions.py 0 | xargs -I '{}' make png/ug-map-'{}'.png

all_150_svgs:
	./list_regions.py 150 | xargs -I '{}' make svg/150/'{}'.svg

all_150_pngs:
	./list_regions.py 150 | xargs -I '{}' make png/150/ug-map-'{}'.png

all_no_zoom_0_svgs:
	./list_regions.py 0 no_zoom | xargs -I '{}' make svg/no_zoom/'{}'.svg

all_no_zoom_0_pngs:
	./list_regions.py 0 no_zoom | xargs -I '{}' make png/no_zoom/ug-map-'{}'-nobox.png

all_no_zoom_150_svgs:
	./list_regions.py 150 no_zoom | xargs -I '{}' make svg/no_zoom/150/'{}'.svg

all_no_zoom_150_pngs:
	./list_regions.py 150 no_zoom | xargs -I '{}' make png/no_zoom/150/ug-map-'{}'-nobox.png

all_no_zoom_11.5_svgs:
	./list_regions.py 11.5 no_zoom | xargs -I '{}' make svg/no_zoom/11.5/'{}'.svg

all_no_zoom_11.5_pngs:
	./list_regions.py 11.5 no_zoom | xargs -I '{}' make png/no_zoom/11.5/ug-map-'{}'-nobox.png

all_svgs: all_0_svgs all_150_svgs all_no_zoom_0_svgs all_no_zoom_150_svgs

all_pngs: all_0_pngs all_150_pngs all_no_zoom_0_pngs all_no_zoom_150_pngs

all_tests:
	bash tests/consistent_output.sh

all_tests_verbose:
	bash tests/consistent_output.sh "display_diff"

# Remove all the SHPs other than those fetched from the web
clean_shp:
	rm -r shp/dissolved shp/intermediate shp/misc shp/projected_w3 shp/recut shp/simplified

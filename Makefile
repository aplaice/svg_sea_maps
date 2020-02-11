MS = ./node_modules/mapshaper/bin/mapshaper

# Is the SVG supposed to be interactive (load controls.js)?
INTERACTIVE ?= yes

MAIN_MAP_SHAPEFILES ::= shp/simplified/ne_10m_lakes.shp \
shp/upstream/ne_10m_geography_marine_polys.shp \
shp/upstream/ne_50m_admin_0_countries_lakes.shp \
shp/upstream/ne_10m_admin_0_boundary_lines_land.shp \
shp/upstream/ne_50m_admin_0_boundary_lines_disputed_areas.shp \
shp/dissolved/ne_50m_land.shp

MAIN_MAP_0_SHAPEFILES ::= $(MAIN_MAP_SHAPEFILES) shp/upstream/ne_10m_wgs84_bounding_box.shp

MINI_MAP_0_SHAPEFILES ::= shp/upstream/ne_110m_land.shp \
shp/upstream/ne_10m_wgs84_bounding_box.shp

MAIN_MAP_150_SHAPEFILES ::= $(MAIN_MAP_SHAPEFILES) shp/misc/150_centred_bounding_box.shp
MAIN_MAP_150_SHAPEFILES ::= $(patsubst shp/%,shp/projected_w3/150/%, $(MAIN_MAP_150_SHAPEFILES))

MINI_MAP_150_SHAPEFILES ::= shp/recut/150/upstream/ne_110m_land.shp \
shp/misc/150_centred_bounding_box.shp

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

# we can't use the "clip boxes" method of recutting, (see below) as it
# can't merge/dissolve East Siberia correctly. (However much
# dissolving and cleaning one does, the border at the anti-meridian
# still remains.)
shp/projected_w3/150/%.shp: shp/%.shp recut_shapefile.sh
	./recut_shapefile.sh "$*" use_geoproject_intermediate

# do not use geostitch and geoproject for ne_110m_land (used for the
# mini-map) as the reflectY(true) step causes the Caspian Sea to
# disappear.
shp/recut/150/%.shp: shp/%.shp recut_shapefile.sh
	./recut_shapefile.sh "$*"

shp/misc/150_centred_bounding_box.shp: shp/upstream/ne_10m_wgs84_bounding_box.shp 150_bounding_box.py
	mkdir -p shp/misc/ shp/intermediate/geojson/
	./150_bounding_box.py
	$(MS) "shp/intermediate/geojson/150_centred_bounding_box.geojson" -o "$@"

svg/intermediate/main_map.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES)
	./main_map.sh

svg/intermediate/mini_map.svg: mini_map.sh $(MINI_MAP_0_SHAPEFILES)
	./mini_map.sh

svg/intermediate/150/main_map.svg: main_map.sh $(MAIN_MAP_150_SHAPEFILES)
	./main_map.sh 150

svg/intermediate/150/mini_map.svg: mini_map.sh $(MINI_MAP_150_SHAPEFILES)
	./mini_map.sh 150

svg/intermediate/main_map_for_aral_sea.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/upstream/ne_10m_lakes_historic.shp
	./main_map.sh 0 aral_sea

svg/intermediate/main_map_for_celtic_sea.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/from_kml/Celtic_Sea.shp
	./main_map.sh 0 celtic_sea

svg/intermediate/main_map_for_english_channel.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/from_kml/English_Channel.shp
	./main_map.sh 0 english_channel

svg/intermediate/150/main_map_for_banda_sea.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/projected_w3/150/from_kml/Banda_Sea.shp
	./main_map.sh 150 banda_sea

svg/intermediate/150/main_map_for_bering_strait.svg: main_map.sh $(MAIN_MAP_150_SHAPEFILES) shp/projected_w3/150/original/bering_strait.shp
	./main_map.sh 150 bering_strait

svg/intermediate/main_map_for_balkan_peninsula.svg: main_map.sh $(MAIN_MAP_0_SHAPEFILES) shp/upstream/ne_10m_geography_regions_polys.shp
	./main_map.sh 0 balkan_peninsula

svg/combined_map.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/main_map.svg
	./combined_map.py

svg/150/%.svg: combined_map.py svg/intermediate/150/mini_map.svg svg/intermediate/150/main_map.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" $* 150

svg/%.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/main_map.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" $*

svg/aral_sea.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/main_map_for_aral_sea.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" aral_sea

svg/celtic_sea.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/main_map_for_celtic_sea.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" celtic_sea

svg/english_channel.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/main_map_for_english_channel.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" english_channel

svg/150/banda_sea.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/150/main_map_for_banda_sea.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" banda_sea 150

svg/150/bering_strait.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/150/main_map_for_bering_strait.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" bering_strait 150

svg/balkan_peninsula.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/main_map_for_balkan_peninsula.svg map_data.json
	./combined_map.py --interactive="$(INTERACTIVE)" balkan_peninsula 0

# When making PNGs the SVGs are considered intermediate files.
# Normally, make would delete them after making the PNGs. To avoid
# that mark them as ".PRECIOUS"
# Ditto for SHP files.
.PRECIOUS: svg/%.svg svg/150/%.svg shp/upstream/%.shp shp/from_kml/%.shp

# not implemented yet
%_interactive.svg: combined_map.py svg/intermediate/mini_map.svg svg/intermediate/main_map.svg map_data.json
	./combined_map.py $* interactive

png/ug-map-%.png: svg/%.svg
	mkdir -p png/
	inkscape "$<" --export-png="$@" -w 500
	optipng "$@"

png/150/ug-map-%.png: svg/150/%.svg
	mkdir -p png/150/
	inkscape "$<" --export-png="$@" -w 500
	optipng "$@"

.PHONY: all_0_svgs all_0_pngs all_150_svgs all_150_pngs all_tests

all_0_svgs:
	./list_regions.py 0 | xargs -I '{}' make svg/'{}'.svg

all_0_pngs:
	./list_regions.py 0 | xargs -I '{}' make png/ug-map-'{}'.png

all_150_svgs:
	./list_regions.py 150 | xargs -I '{}' make svg/150/'{}'.svg

all_150_pngs:
	./list_regions.py 150 | xargs -I '{}' make png/150/ug-map-'{}'.png

all_svgs: all_0_svgs all_150_svgs

all_pngs: all_0_pngs all_150_pngs

all_tests:
	bash tests/consistent_output.sh

all_tests_verbose:
	bash tests/consistent_output.sh "display_diff"

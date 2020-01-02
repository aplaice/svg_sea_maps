#!/bin/bash

mkdir -p shp/upstream/kml
cd shp/upstream/kml
wget https://doi.pangaea.de/10013/epic.37175.d016 -O OceanDB.zip
unzip OceanDB.zip

mkdir -p shp/from_kml/
ogr2ogr -append -f  "ESRI Shapefile" shp/from_kml/ "$<"

mkdir -p shp/from_kml/
ogr2ogr -append -f  "ESRI Shapefile" shp/from_kml/ shp/upstream/kml/OceanDB.kml

#!/bin/bash

mkdir -p shp/upstream/
shp_target="${1#shp/upstream/}"
upstream_url=$(grep "$shp_target"$'\t' upstream_sources.tsv | cut -f 2)

cd shp/upstream/
wget "$upstream_url"
unzip "${shp_target/%.shp/.zip}"

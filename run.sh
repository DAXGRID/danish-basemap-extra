#!/usr/bin/env bash

set -e

output_dir="$(pwd)/data"

log_time_text() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1"
}

log_time_text 'Creating output dir $output_dir'
mkdir -p $output_dir

log_time_text 'Starting download files.'
./DanishGeoJsonExtractor "$(pwd)/appsettings.json"

# Bygning
log_time_text 'Extracting only necessary properties from bygning.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'bygning' as objecttype, status FROM bygning" $output_dir/danish-basemap.geojson $output_dir/bygning.geojson

# Skel
log_time_text 'Extracting only necessary properties from skel.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'skel' as objecttype FROM matrikelskel" $output_dir/danish-basemap.geojson $output_dir/matrikelskel.geojson

# Vejkant
log_time_text 'Extracting only necessary properties from vejkant.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'vejkant' as objecttype FROM vejkant" $output_dir/danish-basemap.geojson $output_dir/vejkant.geojson

# Vejmidte
log_time_text 'Extracting only necessary properties from vejmidte.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'vejmidte' as objecttype FROM vejmidte" $output_dir/danish-basemap.geojson $output_dir/vejmidte.geojson

# Helle
log_time_text 'Extracting only necessary properties from helle.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'helle' as objecttype FROM helle" $output_dir/danish-basemap.geojson $output_dir/helle.geojson

# Nedloebsrist
log_time_text 'Extracting only necessary properties from nedloebsrist.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'nedloebsrist' as objecttype FROM nedloebsrist" $output_dir/danish-basemap.geojson $output_dir/nedloebsrist.geojson

# Broenddaeksel
log_time_text 'Extracting only necessary properties from broenddaeksel.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'broenddaeksel' as objecttype FROM broenddaeksel" $output_dir/danish-basemap.geojson $output_dir/broenddaeksel.geojson

# Lysmast
log_time_text 'Extracting only necessary properties from mast.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'mast' as objecttype FROM mast" $output_dir/danish-basemap.geojson $output_dir/mast.geojson

# Hegn
log_time_text 'Extracting only necessary properties from hegn.'
ogr2ogr -f GeoJSONSeq -append -sql "SELECT 'hegn' as objecttype FROM hegn" $output_dir/danish-basemap.geojson $output_dir/hegn.geojson

# Building tileset
log_time_text 'Building tileset from danish-basemap.geojson.'
tippecanoe --minimum-zoom=16 --maximum-zoom=16 --force --output=$output_dir/objects.mbtiles $output_dir/danish-basemap.geojson

# Upload file to the filesever
curl -u $(FILE_SERVER_USERNAME):$(FILE_SERVER_PASSWORD) -F 'file=@$(output_dir/objects.mbtiles)' '$(FILE_SERVER_URI)/?upload'

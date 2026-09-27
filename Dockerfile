# Build danish geojson extractor
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build-extractor

RUN apk add --no-cache git

WORKDIR /

RUN git clone https://github.com/DAXGRID/danish-geojson-extractor.git repo

WORKDIR /repo

RUN git checkout d9f29d06719d14d454abf1cafe82efe4a106d4bb

RUN dotnet publish -r linux-x64 -p:PublishSingleFile=true --self-contained true --property:PublishDir=/danish-geojson-extractor

FROM alpine AS tippecanoe-builder

WORKDIR /tmp

RUN apk add --no-cache build-base git zlib-dev sqlite-dev bash

RUN git clone --depth 1 --branch 2.79.0 https://github.com/felt/tippecanoe.git tippecanoe-src

RUN make -C tippecanoe-src -j"$(nproc)"

RUN make -C tippecanoe-src install

# Runtime image
FROM alpine

WORKDIR /

# libicu is needed to support unicode in the DanishGeoJsonExtractor.
# bash is needed to run our bash shell script.
# curl is needed to upload the file to the file-server.
# python3 is needed for Python script to include 'vejnavn' to 'vejmidte'.
# python3-ijson is required to stream JSON files in the python script.
# python3-simplejson is required to handle decimal numbers in python script.
RUN apk add --no-cache \
    bash \
    gdal \
    icu-libs \
    git \
    curl \
    python3 \
    py3-ijson \
    py3-simplejson

COPY --from=tippecanoe-builder /usr/local/bin/tippecanoe /usr/local/bin/

WORKDIR /app

COPY --from=build-extractor /danish-geojson-extractor/DanishGeoJsonExtractor .
COPY run.sh .
COPY add_vejnavn_to_vejmidte.py .

ENTRYPOINT ["./run.sh"]

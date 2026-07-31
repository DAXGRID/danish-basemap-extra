# Build danish geojson extractor
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build-extractor

RUN apt-get update && \
    apt-get install git

WORKDIR /

RUN git clone https://github.com/DAXGRID/danish-geojson-extractor.git repo

WORKDIR /repo

RUN git checkout d9f29d06719d14d454abf1cafe82efe4a106d4bb

RUN dotnet publish -r linux-x64 -p:PublishSingleFile=true --self-contained true --property:PublishDir=/danish-geojson-extractor

# Runtime image
FROM debian:stable

WORKDIR /

# libicu is needed to support unicode in the DanishGeoJsonExtractor.
# bash is needed to run our bash shell script.
# build essentials and libsqlite and zlib1g is needed for tippecanoe.
# curl is needed to upload the file to the file-server.
# python3 is needed for Python script to include 'vejnavn' to 'vejmidte'.
# python3-ijson is required to stream JSON files in the python script.
# python3-simplejson is required to handle decimal numbers in python script.
RUN apt-get update && \
    apt-get install -y \
    bash \
    gdal-bin \
    build-essential \
    libicu76 \
    libsqlite3-dev \
    zlib1g-dev \
    git \
    curl \
    python3 \
    python3-ijson \
    python3-simplejson

# Build tippecanoe .
RUN git clone -b 2.79.0 https://github.com/felt/tippecanoe.git

WORKDIR /tippecanoe

RUN make && make install

# Remove the temp directory and unneeded packages.
WORKDIR /
RUN rm -rf /tmp/tippecanoe-src \
  && apt-get -y remove --purge build-essential && apt-get -y autoremove

WORKDIR /app

COPY --from=build-extractor /danish-geojson-extractor/DanishGeoJsonExtractor .
COPY run.sh .
COPY add_vejnavn_to_vejmidte.py .

ENTRYPOINT ["./run.sh"]

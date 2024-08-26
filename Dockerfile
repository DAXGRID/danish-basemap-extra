# Build danish geojson extractor
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-extractor

RUN apt-get update && \
    apt-get install git

WORKDIR /

RUN git clone https://github.com/DAXGRID/danish-geojson-extractor.git repo

WORKDIR /repo

RUN git checkout 7e53306c79ca06f93984ff5f12efab0189343903

RUN dotnet publish -r linux-x64 -p:PublishSingleFile=true --self-contained true --property:PublishDir=/danish-geojson-extractor

# Runtime image
FROM debian:stable-20230703

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
    bash=5.2.15-2+b2 \
    libicu72=72.1-3 \
    gdal-bin=3.6.2+dfsg-1+b2 \
    build-essential=12.9 \
    libsqlite3-dev=3.40.1-2 \
    zlib1g-dev=1:1.2.13.dfsg-1 \
    git=1:2.39.2-1.1 \
    curl=7.88.1-10+deb12u6 \
    python3=3.11.2-1+b1 \
    python3-ijson=3.2.0-1 \
    python3-simplejson=3.18.3-1

# Build tippecanoe .
RUN git clone -b 1.36.0 https://github.com/mapbox/tippecanoe.git

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

# Build danish geojson extractor
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-extractor

RUN apt-get update && \
    apt-get install git

WORKDIR /

RUN git clone https://github.com/DAXGRID/danish-geojson-extractor.git repo

WORKDIR /repo

RUN dotnet publish -r linux-x64 -p:PublishSingleFile=true --self-contained true -o /danish-geojson-extractor

# Runtime image
FROM debian:stable-20230703

WORKDIR /

# libicu is needed to support unicode in the DanishGeoJsonExtractor.
# bash is needed to run our bash shell script.
# Build essentials and libsqlite and zlib1g is needed for tippecanoe.
RUN apt-get update && \
    apt-get install -y bash libicu72 gdal-bin build-essential libsqlite3-dev zlib1g-dev git

# Build tippecanoe .
RUN git clone https://github.com/mapbox/tippecanoe.git

WORKDIR /tippecanoe

RUN make \
  && make install

# Remove the temp directory and unneeded packages.
WORKDIR /
RUN rm -rf /tmp/tippecanoe-src \
  && apt-get -y remove --purge build-essential && apt-get -y autoremove

WORKDIR /app

COPY --from=build-extractor /danish-geojson-extractor/DanishGeoJsonExtractor .
COPY run.sh .

ENTRYPOINT ["./run.sh"]

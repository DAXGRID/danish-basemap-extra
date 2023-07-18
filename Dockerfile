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

WORKDIR /app

# libicu is needed to support unicode in the DanishGeoJsonExtractor.
# bash is needed to run our bash shell script.
RUN apt-get update && \
    apt-get install -y bash libicu72 gdal-bin

COPY --from=build-extractor /danish-geojson-extractor/DanishGeoJsonExtractor .
COPY /appsettings.json .
COPY run.sh .

ENTRYPOINT ["./run.sh"]

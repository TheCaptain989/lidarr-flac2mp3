# syntax=docker/dockerfile:1

## Buildstage ##
FROM ghcr.io/linuxserver/baseimage-alpine:3.20 as buildstage
ARG MOD_VERSION

# copy local files
COPY root/ /root-layer/

# Add version to script
RUN \
  MOD_VERSION="${MOD_VERSION:-unknown}" && \
  sed -i -e "s/{{VERSION}}/$MOD_VERSION/" \
    /root-layer/usr/local/bin/flac2mp3.sh \
    /root-layer/etc/s6-overlay/s6-rc.d/init-mod-lidarr-flac2mp3-add-package/run

## Single layer deployed image ##
FROM scratch
ARG MOD_VERSION

LABEL org.opencontainers.image.title=lidarr-flac2mp3
LABEL org.opencontainers.image.description="A Docker Mod to Lidarr to automatically convert FLAC files to MP3s, or other format"
LABEL org.opencontainers.image.version="${MOD_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/TheCaptain989/lidarr-flac2mp3"
LABEL org.opencontainers.image.authors="TheCaptain989 <thecaptain989@protonmail.com>"
LABEL org.opencontainers.image.licenses=GPL-3.0-only

# Add files from buildstage
COPY --from=buildstage /root-layer/ /

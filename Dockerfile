# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.17 as buildstage

ARG MOD_VERSION

COPY root/ /root-layer/

RUN \
  MOD_VERSION="${MOD_VERSION:-unknown}" && \
  sed -i -e "s/{{VERSION}}/$MOD_VERSION/" \
    /root-layer/usr/local/bin/flac2mp3.sh \
    /root-layer/etc/s6-overlay/s6-rc.d/init-mod-lidarr-flac2mp3-add-package/run

## Single layer deployed image ##
FROM scratch

LABEL org.opencontainers.image.source=https://github.com/TheCaptain989/lidarr-flac2mp3
LABEL org.opencontainers.image.description="A Docker Mod to Lidarr to automatically convert FLAC files to MP3s, or other format"
LABEL org.opencontainers.image.licenses=GPL-3.0-only
LABEL maintainer="TheCaptain989"

# Copy local files
COPY --from=buildstage /root-layer/ /

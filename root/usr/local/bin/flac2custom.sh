#!/bin/bash

if [ -z "$FLAC2CUSTOM_ARGS" ]; then
    echo "[flac2custom] Empty FLAC2CUSTOM_ARGS environment variable" >&2
    exit 1
fi

args=()
dumpargs() { for i in "$@"; do args+=("$i"); done; }
eval dumpargs "$FLAC2CUSTOM_ARGS"

. /usr/local/bin/flac2mp3.sh "${args[@]}"

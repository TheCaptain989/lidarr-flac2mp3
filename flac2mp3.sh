#!/bin/bash

LOG=/config/logs/flac2mp3.txt
ENVLOG=/config/logs/debugenv.txt

# For debug purposes only
#echo --------$(date +"%F %T")-------- >>"$ENVLOG"
#printenv | sort >>"$ENVLOG"

echo $(date +"%F %T")\|Event: "$lidarr_eventtype"\|Artist: "$lidarr_artist_name"\|Converting "$lidarr_artist_path" >>"$LOG"
find "$lidarr_artist_path" -name "*.flac" -exec bash -c 'ffmpeg -loglevel warning -i "{}" -y -acodec libmp3lame -b:a 320k "${0/.flac}.mp3" && rm "{}"' {} \;
echo $(date +"%F %T")\|Done >>"$LOG"

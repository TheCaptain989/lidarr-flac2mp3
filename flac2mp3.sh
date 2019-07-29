#!/bin/bash

LOG=/config/logs/flac2mp3.txt
MAXLOGSIZE=1048576
MAXLOG=4
TRACKS="$lidarr_addedpaths"
[ -z "$TRACKS" ] && TRACKS="$lidarr_trackfile_path"      # For other event type

# For debug purposes only
#ENVLOG=/config/logs/debugenv.txt
#echo --------$(date +"%F %T")-------- >>"$ENVLOG"
#printenv | sort >>"$ENVLOG"

# Can still go over MAXLOG if read line is too long
#  Must include whole function in subshell for read to work!
function log {(
  while read
  do
    echo $(date +"%F %T")\|"$REPLY" >>"$LOG"
    FILESIZE=`wc -c "$LOG" | cut -d' ' -f1`
    if [ $FILESIZE -gt $MAXLOGSIZE ]
    then
      for i in `seq $((MAXLOG-1)) -1 0`
      do
        [ -f "${LOG::-4}.$i.txt" ] && mv "${LOG::-4}."{$i,$((i+1))}".txt"
      done
      touch "$LOG"
    fi
  done
)}

if [ -z "$TRACKS" ]
then
  MSG="ERROR: No track file(s) specified! Not called from Lidarr?"
  echo "$MSG" | log
  echo "$MSG"
  exit 1
fi

echo "Lidarr event: $lidarr_eventtype|Artist: $lidarr_artist_name|Using: $TRACKS" | log

# Legacy script
#find "$lidarr_artist_path" -name "*.flac" -exec bash -c 'ffmpeg -loglevel warning -i "{}" -y -acodec libmp3lame -b:a 320k "${0/.flac}.mp3" && rm "{}"' {} \;

echo "$TRACKS" | awk '
BEGIN {
  FFMpeg="/usr/bin/ffmpeg"
  RS="|"
  IGNORECASE=1
}
/\.flac/ {
  Track=$1
  NewTrack=substr(Track, 1, length(Track)-5)".mp3"
  print "Executing: "FFMpeg" -loglevel warning -i \""Track"\" -y -acodec libmp3lame -b:a 320k \""NewTrack"\""
  Result=system(FFMpeg" -loglevel warning -i \""Track"\" -y -acodec libmp3lame -b:a 320k \""NewTrack"\"")
  if (Result>1) print "ERROR: "Result" converting \""Track"\""
}' | log

echo "Done" | log

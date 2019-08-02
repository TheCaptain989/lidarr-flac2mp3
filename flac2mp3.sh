#!/bin/bash

LIDARR_CONFIG=/config/config.xml
LOG=/config/logs/flac2mp3.txt
MAXLOGSIZE=1048576
MAXLOG=4
TRACKS="$lidarr_addedtrackpaths"
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

# Legacy script
#find "$lidarr_artist_path" -name "*.flac" -exec bash -c 'ffmpeg -loglevel warning -i "{}" -y -acodec libmp3lame -b:a 320k "${0/.flac}.mp3" && rm "{}"' {} \;

echo "Lidarr event: $lidarr_eventtype|Artist: $lidarr_artist_name|Using: $TRACKS" | log
echo "$TRACKS" | awk '
BEGIN {
  FFMpeg="/usr/bin/ffmpeg"
  FS="|"
  RS="|"
  IGNORECASE=1
}
/\.flac/ {
  Track=$1
  sub(/\n/,"",Track)
  NewTrack=substr(Track, 1, length(Track)-5)".mp3"
  print "Executing: "FFMpeg" -loglevel warning -i \""Track"\" -y -acodec libmp3lame -b:a 320k \""NewTrack"\""
  Result=system(FFMpeg" -loglevel warning -i \""Track"\" -y -acodec libmp3lame -b:a 320k \""NewTrack"\"")
  if (Result>0){
    print "ERROR: "Result" converting \""Track"\""
  } else {
    print "Deleting: \""Track"\""
    system("[ -f \""Track"\" ] && rm \""Track"\"")
  }
}' | log

# Call Lidarr API to RescanArtist
if [ ! -z "$lidarr_artist_id" ]
then
  # Inspired by https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
  read_xml () {
    local IFS=\>
    read -d \< ENTITY CONTENT
  }
  
  # Read Lidarr config.xml
  while read_xml; do
    [[ $ENTITY = "Port" ]] && PORT=$CONTENT
    [[ $ENTITY = "UrlBase" ]] && URLBASE=$CONTENT
    [[ $ENTITY = "BindAddress" ]] && BINDADDRESS=$CONTENT
    [[ $ENTITY = "ApiKey" ]] && APIKEY=$CONTENT
  done < $LIDARR_CONFIG
  
  [[ $BINDADDRESS = "*" ]] && BINDADDRESS=localhost
  
  echo "Calling Lidarr API using artist id '$lidarr_artist_id' and URL 'http://$BINDADDRESS:$PORT$URLBASE/api/v1/command?apikey=$APIKEY'" | log
  # Calling API
  RESULT=$(curl -s -d '{name: "RescanArtist", artistId: "$lidarr_artist_id"}' -H "Content-Type: application/json" \
    -X POST http://$BINDADDRESS:$PORT$URLBASE/api/v1/command?apikey=$APIKEY | jq -c '. | {JobId: .id, ArtistId: .body.artistId, Message: .body.completionMessage, DateStarted: .queued}')
  echo "API returned: $RESULT" | log
else
  MSG="ERROR: Missing environment variable lidarr_artist_id"
  echo "$MSG" | log
  echo "$MSG"
  exit 11
fi

echo "Done" | log

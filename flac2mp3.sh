#!/bin/bash

# Script to convert FLAC files to MP3 using FFMpeg
#  https://github.com/TheCaptain989/lidarr-flac2mp3
# Can also process MP3s and tag them appropriately
# Resultant MP3s are fully tagged

# Dependencies:
#  ffmpeg
#  awk

# Exit codes:
#  0 - success
#  1 - no tracks files specified on command line
# 11 - success, but unable to access Lidarr API due to missing Artist ID
# 12 - success, but unable to access Lidarr API due to missing config file

LIDARR_CONFIG=/config/config.xml
LOG=/config/logs/flac2mp3.txt
MAXLOGSIZE=1024000
MAXLOG=4
TRACKS="$lidarr_addedtrackpaths"
[ -z "$TRACKS" ] && TRACKS="$lidarr_trackfile_path"      # For other event type

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
        [ -f "${LOG::-4}.txt" ] && mv "${LOG::-4}.txt" "${LOG::-4}.0.txt"
      touch "$LOG"
    fi
  done
)}

# Process options
while getopts ":db:" opt; do
  case ${opt} in
    d ) # For debug purposes only
      MSG="DEBUG: Enabling debug logging."
      echo "$MSG" | log
      echo "$MSG"
      ENVLOG=/config/logs/debugenv.txt
      echo "--------$(date +"%F %T")--------" >>"$ENVLOG"
      printenv | sort >>"$ENVLOG"
      ;;
    b ) # Set bitrate
      BITRATE="$OPTARG"
      ;;
    : )
      MSG="Invalid option: -$OPTARG requires an argument"
      echo "$MSG" | log
      echo "$MSG"
      ;;
  esac
done
shift $((OPTIND -1))

# Set default bitrate
[ -z "$BITRATE" ] && BITRATE="320k"

if [[ "$lidarr_eventtype" = "Test" ]]; then
  echo "Lidarr event: $lidarr_eventtype" | log
  echo "Script was test executed successfully." | log
  exit 0
fi

if [ -z "$TRACKS" ]; then
  MSG="ERROR: No track file(s) specified! Not called from Lidarr?"
  echo "$MSG" | log
  echo "$MSG"
  exit 1
fi

# Legacy one-liner script
#find "$lidarr_artist_path" -name "*.flac" -exec bash -c 'ffmpeg -loglevel warning -i "{}" -y -acodec libmp3lame -b:a 320k "${0/.flac}.mp3" && rm "{}"' {} \;

echo "Lidarr event: $lidarr_eventtype|Artist: $lidarr_artist_name|Artist ID: $lidarr_artist_id|Album ID: $lidarr_album_id|Tracks: $TRACKS" | log
echo "Export bitrate: $BITRATE" | log
echo "$TRACKS" | awk '
BEGIN {
  FFMpeg="/usr/bin/ffmpeg"
  FS="|"
  RS="|"
  IGNORECASE=1
  Cover="/config/MediaCover/Albums/'$lidarr_album_id'/cover.jpg"
  if (system("[ -f \""Cover"\" ]") == 0){
    CoverCmds1="-i \""Cover"\" -map 1 "
    CoverCmds2="-vcodec:v:1 copy -metadata:s:v title=\"Album cover\" -metadata:s:v comment=\"Cover (front)\" "
  }
}
/\.flac/ {
  Track=$1
  sub(/\n/,"",Track)
  NewTrack=substr(Track, 1, length(Track)-5)".mp3"
  print "Executing: "FFMpeg" -loglevel warning -i \""Track"\" "CoverCmds1"-map 0 -y -acodec libmp3lame -b:a '$BITRATE' -write_id3v1 1 -id3v2_version 3 "CoverCmds2"\""NewTrack"\""
  Result=system(FFMpeg" -loglevel warning -i \""Track"\" "CoverCmds1"-map 0 -y -acodec libmp3lame -b:a '$BITRATE' -write_id3v1 1 -id3v2_version 3 "CoverCmds2"\""NewTrack"\" 2>&1")
  if (Result) {
    print "ERROR: "Result" converting \""Track"\""
  } else {
    print "Deleting: \""Track"\""
    system("[ -s \""NewTrack"\" ] && [ -f \""Track"\" ] && rm \""Track"\"")
  }
}
/\.mp3/ {
  Track=$1
  sub(/\n/,"",Track)
  TmpTrack=substr(Track, 1, length(Track)-4)".tmp"
  print "Executing: "FFMpeg" -loglevel warning -i \""Track"\" "CoverCmds1"-map 0 -y -acodec copy -write_id3v1 1 -id3v2_version 3 "CoverCmds2"-f mp3 \""TmpTrack"\""
  Result=system(FFMpeg" -loglevel warning -i \""Track"\" "CoverCmds1"-map 0 -y -acodec copy -write_id3v1 1 -id3v2_version 3 "CoverCmds2"-f mp3 \""TmpTrack"\" 2>&1")
  if (Result) {
    print "ERROR: "Result" converting \""Track"\""
  } else {
    print "Deleting: \""Track"\" and Renaming: \""TmpTrack"\""
    system("[ -s \""TmpTrack"\" ] && [ -f \""Track"\" ] && rm \""Track"\" && mv \""TmpTrack"\" \""Track"\"")
  }
}' | log

# Call Lidarr API to RescanArtist
if [ ! -z "$lidarr_artist_id" ]; then
  if [ -f "$LIDARR_CONFIG" ]; then
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
    
    echo "Calling Lidarr API 'RefreshArtist' using artist id '$lidarr_artist_id' and URL 'http://$BINDADDRESS:$PORT$URLBASE/api/v1/command?apikey=$APIKEY'" | log
    # Calling API
    RESULT=$(curl -s -d "{name: 'RefreshArtist', artistId: $lidarr_artist_id}" -H "Content-Type: application/json" \
      -X POST http://$BINDADDRESS:$PORT$URLBASE/api/v1/command?apikey=$APIKEY | jq -c '. | {JobId: .id, ArtistId: .body.artistId, Message: .status, DateStarted: .queued}')
    echo "API returned: $RESULT" | log
  else
    echo "ERROR: Unable to locate Lidarr config file: '$LIDARR_CONFIG'" | log
    exit 12
  fi
else
  echo "ERROR: Missing environment variable lidarr_artist_id" | log
  exit 11
fi

echo "Done" | log

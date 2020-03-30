#!/bin/bash

# Script to convert FLAC files to MP3 using FFMpeg
#  https://github.com/TheCaptain989/lidarr-flac2mp3
# Can also process MP3s and tag them appropriately
# Resultant MP3s are fully tagged

# Dependencies:
#  ffmpeg
#  awk

# Exit codes:
#  0 - success; or test
#  1 - no tracks files specified on command line
# 11 - success, but unable to access Lidarr API due to missing Artist ID
# 12 - success, but unable to access Lidarr API due to missing config file

SCRIPT=$(basename "$0")
LIDARR_CONFIG=/config/config.xml
LOG=/config/logs/flac2mp3.txt
MAXLOGSIZE=1024000
MAXLOG=4
DEBUG=0
TRACKS="$lidarr_addedtrackpaths"
[ -z "$TRACKS" ] && TRACKS="$lidarr_trackfile_path"      # For other event type
RECYCLEBIN=$(python -c "import sqlite3
conSql = sqlite3.connect('/config/lidarr.db')
cursorObj = conSql.cursor()
cursorObj.execute('SELECT Value from Config WHERE Key=\"recyclebin\"')
print(cursorObj.fetchone()[0])
conSql.close()")

function usage {
  usage="
$SCRIPT
Audio conversion script designed for use with Bazarr

Source: https://github.com/TheCaptain989/lidarr-flac2mp3

Usage:
  $0 [-d] [-b <bitrate>]

Arguments:
  bitrate       # output quality in bits per second (SI units)

Options:
  -d    # enable debug logging
  -b    # set bitrate; default 320K

Examples:
  $SCRIPT -b 320k              # Output 320 kilobits per second MP3
                                     (same as default behavior)
  $SCRIPT -d -b 160k           # Enable debugging, and output quality
                                     160 kilobits per second
"
  echo "$usage"
}

# Can still go over MAXLOG if read line is too long
#  Must include whole function in subshell for read to work!
function log {(
  while read
  do
    echo $(date +"%y-%-m-%-d %H:%M:%S.%1N")\|"$REPLY" >>"$LOG"
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
      MSG="Debug|Enabling debug logging."
      echo "$MSG" | log
      echo "$MSG"
      DEBUG=1
      printenv | sort | sed 's/^/Debug|/' | log
      ;;
    b ) # Set bitrate
      BITRATE="$OPTARG"
      ;;
    : )
      MSG="Error|Invalid option: -$OPTARG requires an argument"
      echo "$MSG" | log
      echo "$MSG"
      ;;
  esac
done
shift $((OPTIND -1))

# Set default bitrate
[ -z "$BITRATE" ] && BITRATE="320k"

if [[ "$lidarr_eventtype" = "Test" ]]; then
  echo "Info|Lidarr event: $lidarr_eventtype" | log
  echo "Info|Script was test executed successfully." | log
  exit 0
fi

if [ -z "$TRACKS" ]; then
  MSG="Error|No track file(s) specified! Not called from Lidarr?"
  echo "$MSG" | log
  echo "$MSG"
  usage
  exit 1
fi

# Legacy one-liner script
#find "$lidarr_artist_path" -name "*.flac" -exec bash -c 'ffmpeg -loglevel warning -i "{}" -y -acodec libmp3lame -b:a 320k "${0/.flac}.mp3" && rm "{}"' {} \;

echo "Info|Lidarr event: $lidarr_eventtype, Artist: $lidarr_artist_name ($lidarr_artist_id), Album: $lidarr_album_title ($lidarr_album_id), Export bitrate: $BITRATE, Tracks: $TRACKS" | log
echo "$TRACKS" | awk -v Debug=$Debug -v Recycle="$RECYCLEBIN" -v Bitrate=$BITRATE '
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
  print "Info|Writing: "NewTrack
  if (Debug) print "Debug|Executing: "FFMpeg" -loglevel error -i \""Track"\" "CoverCmds1"-map 0 -y -acodec libmp3lame -b:a "Bitrate" -write_id3v1 1 -id3v2_version 3 "CoverCmds2"\""NewTrack"\""
  Result=system(FFMpeg" -loglevel error -i \""Track"\" "CoverCmds1"-map 0 -y -acodec libmp3lame -b:a "Bitrate" -write_id3v1 1 -id3v2_version 3 "CoverCmds2"\""NewTrack"\" 2>&1")
  if (Result) {
    print "Error|"Result" converting \""Track"\""
  } else {
    if (Recycle=="") {
      if (Debug) print "Debug|Deleting: \""Track"\""
      system("[ -s \""NewTrack"\" ] && [ -f \""Track"\" ] && rm \""Track"\"")
    } else {
      match(Track,/^\/?[^\/]+\//)
      RecPath=substr(Track,RSTART+RLENGTH)
      sub(/[^\/]+$/,"",RecPath)
      RecPath=Recycle RecPath
      if (Debug) print "Debug|Moving: \""Track"\" to \""RecPath"\""
      system("[ ! -e \""RecPath"\" ] && mkdir -p \""RecPath"\"; [ -s \""NewTrack"\" ] && [ -f \""Track"\" ] && mv -t \""RecPath"\" \""Track"\"")
    }
  }
}
' | log

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
    
    [ $DEBUG -eq 1 ] && echo "Debug|Calling Lidarr API 'RefreshArtist' using artist id '$lidarr_artist_id' and URL 'http://$BINDADDRESS:$PORT$URLBASE/api/v1/command?apikey=$APIKEY'" | log
    # Calling API
    RESULT=$(curl -s -d "{name: 'RefreshArtist', artistId: $lidarr_artist_id}" -H "Content-Type: application/json" \
      -X POST http://$BINDADDRESS:$PORT$URLBASE/api/v1/command?apikey=$APIKEY | jq -c '. | {JobId: .id, ArtistId: .body.artistId, Message: .status, DateStarted: .queued}')
    [ $DEBUG -eq 1 ] && echo "Debug|API returned: $RESULT" | log
  else
    echo "Warn|Unable to locate Lidarr config file: '$LIDARR_CONFIG'" | log
    exit 12
  fi
else
  echo "Warn|Missing environment variable lidarr_artist_id" | log
  exit 11
fi

echo "Info|Done" | log

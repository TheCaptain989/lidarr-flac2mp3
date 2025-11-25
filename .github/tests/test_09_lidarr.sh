#!/bin/bash

# bash_unit tests
# Lidarr API
# Lidarr installed from BuildImage.yml

# Used for debugging unit tests
_log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$flac2mp3_pid]$REPLY" >>flac2mp3.txt; done; )}

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  fake log :
  download_track="stereo.flac"
  export test_track2="01 What We Do Is Secret.flac"
  export artist_dir="The Germs"
  export album_dir="$artist_dir/(GI)"
  [ -d "$album_dir" ] || mkdir -p "$album_dir"
  [ -f "$album_dir/$download_track" ] || { wget -q "https://github.com/sfiera/flac-test-files/raw/refs/heads/master/stereo.flac" -O "$album_dir/$download_track"; }
  # Tags needed in test file so it imports correctly
  ffmpeg -loglevel error -i "$album_dir/$download_track" -map 0 -y -codec copy -write_id3v2 1 -metadata "Artist=The Germs" -metadata "Album=(GI)" -metadata "Title=What We Do Is Secret" -metadata "disc=1/1" "$album_dir/$test_track2"
  [ -f "$album_dir/$download_track" ] && rm "$album_dir/$download_track"
}

setup() {
  export lidarr_eventtype="Import"
  initialize_variables
  initialize_mode_variables
  check_log >/dev/null
  check_required_binaries
}

test_lidarr_test_event() {
  export lidarr_eventtype="Test"
  initialize_mode_variables
  assert_equals "Info|Script was test executed successfully." "$(check_eventtype)"
}

test_lidarr_version() {
  fake get_trackfile_info :
  check_eventtype
  check_config
  assert_within_delta 3 ${flac2mp3_version/.*/} 2
}

test_lidarr_call_api_with_json() {
  fake get_trackfile_info :
  check_eventtype
  check_config
  call_api 0 "Creating a test tag." "POST" "tag" '{"label":"test"}'
  assert_equals '{"label":"test","id":1}' "$(echo $flac2mp3_result | jq -jcM)"
}

test_lidarr_call_api_with_urlencode() {
  fake get_trackfile_info :
  check_eventtype
  check_config
  call_api 0 "Getting tmp filesystem info." "GET" "filesystem" "path=/tmp/"
  assert_equals '{"parent":"/","directories":[],"files":[]}' "$(echo $flac2mp3_result | jq -jcM)"
}

test_lidarr_z01_music_load() {
  fake get_trackfile_info :
  sleep 5
  load_music
  assert_equals "$PWD/$album_dir/$test_track2" "$(echo $flac2mp3_result | jq -crM '.[] | .path?')"
}

test_lidarr_z02_convert_music() {
  # fake log _log
  # flac2mp3_debug=1
  # Read in values from first test
  flac2mp3_result="$(cat "$PWD/$album_dir/${test_track2%.flac}.json")"
  lidarr_artist_path="$PWD/$artist_dir"
  lidarr_artist_id="$(echo $flac2mp3_result | jq -crM '.[].artistId')"
  lidarr_album_id="$(echo $flac2mp3_result | jq -crM '.[].albumId')"
  lidarr_artist_name="The Germs"
  lidarr_album_title="(GI)"
  lidarr_addedtrackpaths="$PWD/$album_dir/$test_track2"
  process_command_line
  initialize_mode_variables
  check_eventtype
  log_script_start
  check_config
  set_ffmpeg_parameters
  process_tracks
  update_database
  assert_equals 0 ${flac2mp3_exitstatus:-0}
}

test_lidarr_z03_artist_delete() {
  # fake log _log
  # flac2mp3_debug=1
  fake get_trackfile_info :
  check_config
  # Read in values from first test
  flac2mp3_result="$(cat "$PWD/$album_dir/${test_track2%.flac}.json")"
  lidarr_artist_path="$PWD/$artist_dir"
  lidarr_artist_id="$(echo $flac2mp3_result | jq -crM '.[].artistId')"
  lidarr_album_id="$(echo $flac2mp3_result | jq -crM '.[].albumId')"
  lidarr_artist_name="The Germs"
  lidarr_album_title="(GI)"
  lidarr_addedtrackpaths="$PWD/$album_dir/$test_track2"
  assert_status_code 0 "call_api 0 \"Deleting artist $lidarr_artist_id.\" \"DELETE\" \"artist/$lidarr_artist_id\" \"deleteFiles=true\""
}

load_music() {
  check_config
  call_api 0 "Create root folder." "POST" "rootfolder" "{\"name\":\"Test Root\", \"path\":\"$PWD\", \"defaultMetadataProfileId\":1, \"defaultQualityProfileId\":1}"
  call_api 0 "Adding artist to Lidarr." "POST" "artist" "{\"qualityProfileId\":1, \"metadataProfileId\":1, \"artistName\":\"The Germs\", \"foreignArtistId\":\"42c4b58d-2e28-41d4-bfe5-4edee68386cf\", \"path\":\"$PWD/$artist_dir\", \"rootFolderPath\":\"$PWD\", \"monitored\":true}"
  lidarr_artist_id=$(echo $flac2mp3_result | jq -crM '.id?')
  lidarr_artist_path="$(echo $flac2mp3_result | jq -crM '.path?')"
  sleep 1
  call_api 0 "Getting albums for artist id $lidarr_artist_id." "GET" "album"
  lidarr_album_id=$(echo $flac2mp3_result | jq -crM '.[] | .id?')
  # Needed for next test
  call_api 0 "Getting track file info for album id $lidarr_album_id." "GET" "trackFile" "albumId=$lidarr_album_id"
  echo $flac2mp3_result | jq -r >"$PWD/$album_dir/${test_track2%.flac}.json"
  export flac2mp3_import_list="$PWD/$album_dir/$test_track2"
  flac2mp3_import_count=$(echo $flac2mp3_import_list | awk -F\| '{print NF}')
}

teardown_suite() {
  rm -f -d "./flac2mp3.txt" $album_dir/$download_track "$album_dir/${test_track2%.flac}.mp3" "$album_dir/${test_track2%.flac}.json" "$album_dir/$test_track2" "$album_dir" "$artist_dir"
  unset lidarr_eventtype lidarr_addedtrackpaths flac2mp3_config flac2mp3_version
}
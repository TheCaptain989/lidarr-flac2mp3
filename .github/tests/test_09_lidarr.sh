#!/bin/bash

# bash_unit tests
# lidarr API

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  export test_track2="stereo.flac"
  fake log :
}

setup() {
  [ -f "$test_track2" ] || { wget -q "https://github.com/sfiera/flac-test-files/raw/refs/heads/master/stereo.flac" -O "$test_track2"; }
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
  assert_within_delta 2 ${flac2mp3_version/.*/} 1
}

test_lidarr_call_api_with_json() {
  check_eventtype
  check_config
  call_api 0 "Creating a test tag." "POST" "tag" '{"label":"test"}'
  assert_equals '{"label":"test","id":1}' "$(echo $striptracks_result | jq -jcM)"
}

test_lidarr_call_api_with_urlencode() {
  check_eventtype
  check_config
  call_api 0 "Creating a test tag." "GET" "filesystem" "path=/tmp/"
  assert_equals '{"parent":"/","directories":[],"files":[]}' "$(echo $striptracks_result | jq -jcM)"
}

todo_test_track_conversion() {
  fake get_trackfile_info :
  export lidarr_addedtrackpaths="./$test_track2"
  process_command_line
  initialize_mode_variables
  check_tracks
  set_ffmpeg_parameters
  process_tracks
  assert "test ! -f $test_track2" && \
  assert "test -f \"${test_track2%.flac}.mp3\""
  assert_equals 0 $flac2mp3_exitstatus
}

teardown_suite() {
  rm -f "./flac2mp3.txt"
  unset lidarr_eventtype lidarr_addedtrackpaths flac2mp3_config flac2mp3_version
}
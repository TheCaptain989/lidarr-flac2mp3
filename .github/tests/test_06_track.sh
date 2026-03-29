#!/bin/bash

# bash_unit tests
# Track checks

# Used for debugging unit tests
_log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$flac2mp3_pid]$REPLY" >>flac2mp3.txt; done; )}

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
  export flac2mp3_mode="batch"
  export flac2mp3_tracks="test_track.mp3"
  fake log :
}

test_track_var_not_set() {
  unset flac2mp3_tracks
  assert_status_code 1 "check_tracks 2>/dev/null"
}

test_track_not_exist() {
  rm -f "$flac2mp3_tracks"
  assert_status_code 5 "check_tracks 2>/dev/null"
}

test_bad_output_dir() {
  touch $flac2mp3_tracks
  flac2mp3_type="Import"
  process_command_line --output /proc/output
  assert_status_code 6 "check_tracks 2>/dev/null"
}

test_import_mode_single_track() {
  flac2mp3_mode="Import"
  flac2mp3_tracks="test_import.flac"
  touch "$flac2mp3_tracks"
  assert_status_code 0 "check_tracks 2>/dev/null"
  rm -f "$flac2mp3_tracks"
}

test_import_mode_track_not_exist() {
  flac2mp3_mode="Import"
  flac2mp3_tracks="nonexistent.flac"
  assert_status_code 5 "check_tracks 2>/dev/null"
}

teardown() {
  rm -f "$flac2mp3_tracks"
}

teardown_suite() {
  unset flac2mp3_mode flac2mp3_type flac2mp3_tracks flac2mp3_output
}
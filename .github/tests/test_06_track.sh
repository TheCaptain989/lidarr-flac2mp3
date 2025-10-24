#!/bin/bash

# bash_unit tests
# Track checks

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
  export flac2mp3_type="batch"
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
  flac2mp3_type="Import"
  process_command_line --output /proc/output
  assert_status_code 6 "check_tracks 2>/dev/null"
}

teardown_suite() {
  rm -f "$flac2mp3_tracks"
  unset flac2mp3_type flac2mp3_tracks flac2mp3_output
}
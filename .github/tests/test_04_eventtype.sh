#!/bin/bash

# bash_unit tests
# Different eventtype values

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
  process_command_line
  export lidarr_eventtype
  export lidarr_transfermode
  fake log :
}

test_unknown_eventtype() {
  assert_status_code 7 "initialize_mode_variables"
}

test_lidarr_eventtype() {
  lidarr_eventtype="Import"
  lidarr_addedtrackpaths="/music/01.flac"
  initialize_variables
  initialize_mode_variables
  assert_equals "/music/01.flac" "$flac2mp3_tracks"
}

test_unsupported_eventtype() {
  lidarr_eventtype="Grab"
  initialize_variables
  initialize_mode_variables
  assert_status_code 20 "check_eventtype 2>/dev/null"
}

test_test_event() {
  lidarr_eventtype="Test"
  initialize_variables
  initialize_mode_variables
  assert_equals "Info|Script was test executed successfully." "$(check_eventtype)"
}

test_import_mode() {
  lidarr_transfermode="Move"
  lidarr_sourcepath="/#downloads/music/01.flac"
  lidarr_destinationpath="/music/01.flac"
  initialize_variables
  initialize_mode_variables
  assert_equals "Import" "$flac2mp3_mode"
  assert_equals "lidarr" "$flac2mp3_type"
  assert_equals "/#downloads/music/01.flac" "$flac2mp3_tracks"
  assert_equals "/music/01.flac" "$flac2mp3_newtracks"
}

test_import_mode_event() {
  lidarr_transfermode="Move"
  # shellcheck disable=SC2034
  lidarr_sourcepath="/#downloads/music/01.flac"
  # shellcheck disable=SC2034
  lidarr_destinationpath="/music/01.flac"
  initialize_variables
  initialize_mode_variables
  assert_equals "Move" "$flac2mp3_event"
}

teardown() {
  unset lidarr_eventtype flac2mp3_event flac2mp3_tracks lidarr_transfermode flac2mp3_mode flac2mp3_type lidarr_addedtrackpaths
}
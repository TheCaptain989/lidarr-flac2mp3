#!/bin/bash

# bash_unit tests
# Eventtype

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
  process_command_line
  fake log :
}

test_unknown_eventtype() {
  assert_status_code 7 "initialize_mode_variables"
}

test_lidarr_eventtype() {
  export lidarr_eventtype="Import"
  export lidarr_addedtrackpaths="/music/01.flac"
  initialize_variables
  initialize_mode_variables
  assert_equals "/music/01.flac" "$flac2mp3_tracks"
}

test_unsupported_eventtype() {
  export lidarr_eventtype="Grab"
  initialize_variables
  initialize_mode_variables
  assert_status_code 20 "check_eventtype 2>/dev/null"
}

test_test_event() {
  export lidarr_eventtype="Test"
  initialize_variables
  initialize_mode_variables
  assert_equals "Info|Script was test executed successfully." "$(check_eventtype)"
}

teardown() {
  unset lidarr_eventtype flac2mp3_eventtype flac2mp3_tracks
}
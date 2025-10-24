#!/bin/bash

# bash_unit tests
# lidarr API

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  fake log :
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
  check_eventtype
  check_config
  assert_within_delta 5 ${flac2mp3_version/.*/} 1
}

teardown_suite() {
  rm -f "./flac2mp3.txt"
  unset lidarr_eventtype flac2mp3_config
}
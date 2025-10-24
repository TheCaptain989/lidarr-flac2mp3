#!/bin/bash

# bash_unit tests
# Configuration file

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  export lidarr_eventtype="Import"
  initialize_variables
  initialize_mode_variables
  fake log :
}

test_api_url() {
  fake get_version :
  fake get_trackfile_info :
  check_config
  assert_equals "http://localhost:8686/api/v1" "$flac2mp3_api_url"
}

test_api_curl_failure() {
  fake get_version return 1
  assert_status_code 17 "check_config 2>/dev/null"
}

teardown_suite() {
  unset lidarr_eventtype flac2mp3_config
}
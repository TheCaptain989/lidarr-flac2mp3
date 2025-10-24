#!/bin/bash

# bash_unit tests
# Command line options

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
}

test_cmd_options_require_argument() {
  assert_status_code 3 "process_command_line --log" && \
  assert_status_code 3 "process_command_line --file" && \
  assert_status_code 3 "process_command_line --config" && \
  assert_status_code 3 "process_command_line --quality" && \
  assert_status_code 3 "process_command_line --bitrate" && \
  assert_status_code 3 "process_command_line --extension" && \
  assert_status_code 3 "process_command_line --output" && \
  assert_status_code 3 "process_command_line --regex" && \
  assert_status_code 3 "process_command_line --tags"
}

test_cmd_unknown_option() {
  assert_status_code 20 "process_command_line --will-fail 2>&1"
}

test_cmd_invalid_options() {
  assert_status_code 3 "process_command_line -b 128 -v 1 2>&1" && \
  assert_status_code 3 "process_command_line -a \"-a:c aac\" -v 1 2>&1" && \
  assert_status_code 3 "process_command_line -e aac -b 128 2>&1" && \
  assert_status_code 3 "process_command_line -b 128 -a \"-a:c aac\" 2>&1" && \
  assert_status_code 3 "process_command_line -v 1 -e aac 2>&1" && \
  assert_status_code 3 "process_command_line -a \"-a:c aac\""
}

test_keep_option() {
  process_command_line --keep-file
  assert_equals "1" "$flac2mp3_keep"
}

test_defaults() {
  process_command_line
  assert_equals "320k" "$flac2mp3_bitrate" && \
  assert_equals ".mp3" "$flac2mp3_extension"
}

test_set_output_dir() {
  process_command_line --output "/tmp/output/dir"
  assert_equals "/tmp/output/dir/" "$flac2mp3_output"
}

test_env_usage_with_cmd() {
  local FLAC2MP3_ARGS="-a \"-a:c aac\" -e aac"
  process_command_line -b 128
  assert_matches "^Warning\|FLAC2MP3_ARGS environment.*" "$flac2mp3_prelogmessage"
}

test_env_usage() {
  local FLAC2MP3_ARGS="-a \"-a:c aac\" -e aac"
  process_command_line
  assert_equals "Info|Using settings from environment variable." "$flac2mp3_prelogmessage"
}

teardown() {
  unset FLAC2MP3_ARGS flac2mp3_prelogmessage flac2mp3_output flac2mp3_bitrate flac2mp3_extension flac2mp3_keep
}
#!/bin/bash

# bash_unit tests
# Logs

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
}

test_create_log() {
  check_log >/dev/null
  assert_equals "/config/logs/flac2mp3.txt" "$flac2mp3_log" && \
  assert "test -f $flac2mp3_log"
}

todo_log_not_writable() {
  # Doesn't work properly in a container
  local flac2mp3_log="./flac2mp3.txt"
  touch "$flac2mp3_log"
  chmod -f a-w "$flac2mp3_log"
  check_log 2>/dev/null
  assert_equals 4 $flac2mp3_exitstatus
}

teardown() {
  rm -f "./flac2mp3.txt"
  unset flac2mp3_log flac2mp3_exitstatus
}
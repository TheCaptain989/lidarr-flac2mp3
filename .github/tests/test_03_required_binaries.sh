#!/bin/bash

# bash_unit tests
# Required binaries
# ffmpeg installed from BuildImage.yml

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
  fake log :
}

test_binaries_present() {
  assert check_required_binaries
}
test_missing_ffmpeg() {
  mv /usr/bin/ffmpeg /usr/bin/ffmpeg.bak
  assert_status_code 2 "check_required_binaries 2>/dev/null" && \
  assert_matches "^Error\|/usr/bin/ffmpeg is required" "$(check_required_binaries 2>&1)"
  mv /usr/bin/ffmpeg.bak /usr/bin/ffmpeg
}

test_missing_ffprobe() {
  mv /usr/bin/ffprobe /usr/bin/ffprobe.bak
  assert_status_code 2 "check_required_binaries 2>/dev/null" && \
  assert_matches "^Error\|/usr/bin/ffprobe is required" "$(check_required_binaries 2>&1)"
  mv /usr/bin/ffprobe.bak /usr/bin/ffprobe
}
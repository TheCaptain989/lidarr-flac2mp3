#!/bin/bash

# bash_unit tests
# ffmpeg paramater processing checks

setup_suite() {
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
  fake log :
}

test_default_ffmpeg_params() {
  process_command_line
  set_ffmpeg_parameters
  assert_equals "-c:v copy -map 0 -y -acodec libmp3lame -b:a 320k -write_id3v1 1 -id3v2_version 3" "$flac2mp3_ffmpeg_opts"
}

test_cbr_ffmpeg_params() {
  process_command_line -b 128k
  set_ffmpeg_parameters
  assert_equals "-c:v copy -map 0 -y -acodec libmp3lame -b:a 128k -write_id3v1 1 -id3v2_version 3" "$flac2mp3_ffmpeg_opts"
}

test_vbr_ffmpeg_params() {
  process_command_line -v 0
  set_ffmpeg_parameters
  assert_equals "-c:v copy -map 0 -y -acodec libmp3lame -q:a 0 -write_id3v1 1 -id3v2_version 3" "$flac2mp3_ffmpeg_opts"
}

test_advanced_ffmpeg_params() {
  process_command_line -a "-a:c aac -b:a 256k" -e aac
  set_ffmpeg_parameters
  assert_equals "-a:c aac -b:a 256k" "$flac2mp3_ffmpeg_opts"
}

teardown() {
  unset flac2mp3_ffmpeg_opts flac2mp3_bitrate flac2mp3_vbrquality flac2mp3_ffmpegadv
}
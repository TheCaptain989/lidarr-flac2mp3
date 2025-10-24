#!/bin/bash

# bash_unit tests
# Convert audio file
# ffmpeg installed from BuildImage.yml

setup_suite() {
  which ffmpeg >/dev/null || { printf "\t\e[0;91ffmpeg not found\e[0m\n"; exit 1; }
  source ../../root/usr/local/bin/flac2mp3.sh
  initialize_variables
  check_log >/dev/null
  export test_track1="sample-0.wav"
  export test_track2="stereo.flac"
  export test_track3="Pr%C3%B8ve.flac"
  fake log :
}

setup() {
  [ -f "$test_track1" ] || { wget -q "https://github.com/audio-samples/audio-samples.github.io/raw/refs/heads/master/samples/wav/music/sample-0.wav" -O "$test_track1"; }
  [ -f "$test_track2" ] || { wget -q "https://github.com/sfiera/flac-test-files/raw/refs/heads/master/stereo.flac" -O "$test_track2"; }
  [ -f "$test_track3" ] || { wget -q "https://github.com/xiph/flac/raw/refs/heads/master/test/flac-to-flac-metadata-test-files/Pr%C3%B8ve.flac" -O "$test_track3"; }
}

test_convert_track_same_name() {
  process_command_line -f "$test_track1" -a "-c:a pcm_s16le" -e wav -r '\.wav$' -k
  check_tracks
  set_ffmpeg_parameters
  process_tracks 2>/dev/null
  assert_equals 11 $flac2mp3_exitstatus
}

test_convert_track() {
  process_command_line -f "$test_track2"
  check_tracks
  set_ffmpeg_parameters
  process_tracks
  assert "test ! -f $test_track2" && \
  assert "test -f \"${test_track2%.flac}.mp3\""
}

test_vbr() {
  process_command_line -v 0 -f "$test_track2"
  check_tracks
  set_ffmpeg_parameters
  process_tracks
  assert "test ! -f $test_track2" && \
  assert "test -f \"${test_track2%.flac}.mp3\""
}

test_alac() {
  process_command_line -f "$test_track3" -a "-c:a alac" -e m4a
  check_tracks
  set_ffmpeg_parameters
  process_tracks
  assert "test ! -f $test_track3" && \
  assert "test -f \"${test_track3%.flac}.m4a\""
}

teardown_suite() {
  rm -f "$test_track1" "$test_track2" "$test_track3" "${test_track2:0:5}.tmp".* "./flac2mp3.txt" "${test_track1%.wav}.mp3" "${test_track2%.flac}.mp3" "${test_track3%.flac}.m4a"
  unset flac2mp3_prelogmessage flac2mp3_output flac2mp3_extension flac2mp3_keep flac2mp3_tracks flac2mp3_ffmpeg_opts flac2mp3_bitrate flac2mp3_vbrquality flac2mp3_ffmpegadv test_track1 test_track2 test_track3
}
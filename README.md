[![](https://images.microbadger.com/badges/image/thecaptain989/lidarr.svg)](https://microbadger.com/images/thecaptain989/lidarr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/thecaptain989/lidarr.svg)](https://microbadger.com/images/thecaptain989/lidarr "Get your own version badge on microbadger.com")

Lidarr with a script to automatically convert FLAC files to MP3s. The MP3s are fully ID3 tagged by ffmpeg.

# First Things First

Configure the container with all the port, volume, and environment settings from the original container documentation here:  
**[linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr)**

## Usage

After all of the above configuration is complete, to use ffmpeg, configure a custom script from the Settings->Connect screen to call:

**`/usr/local/bin/flac2mp3.sh`**

New track file(s) with an MP3 extension will be placed in the same directory as the original FLAC file(s). Existing MP3 files with the same track name will be overwritten.

**NOTE:** The original FLAC audio file(s) will be deleted and permanently lost.

### Syntax

The script accepts two options:

`[-d] [-b <bitrate>]`

The `-b bitrate` option, if specified, sets the output quality in bits per second.  If no `-b` option is specified, the script will default to 320Kbps.

The only events/notification triggers that have been tested are **On Release Import** and **On Upgrade**

The `-d` option enables debug logging.

### Examples
    -b 320k        # Output 320 kilobits per second MP3 (same as default behavior)
    -d -b 160k     # Enable debugging, and output 160 kilobits per second MP3

![lidarr-flac2mp3](https://raw.githubusercontent.com/TheCaptain989/lidarr-flac2mp3/master/images/flac2mp3.png)

### Logs
A log file is created for the script activity called:

`/config/logs/flac2mp3.txt`

This log can be inspected from the GUI under System->Log Files

Log rotation is performed, with 5 log files of 1MB each kept, matching Lidarr's log retention.

If debug logging is enabled, the following log file is also created:

`/config/logs/debugenv.txt`

**This log file will grow indefinitely!** Do not leave debugging enabled permanently.

## Credits

This would not be possible without the following:

[Lidarr](https://lidarr.audio/)

[LinuxServer.io Lidarr](https://hub.docker.com/r/linuxserver/lidarr) container

[ffmpeg](https://ffmpeg.org/)

[![](https://images.microbadger.com/badges/image/thecaptain989/lidarr.svg)](https://microbadger.com/images/thecaptain989/lidarr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/thecaptain989/lidarr.svg)](https://microbadger.com/images/thecaptain989/lidarr "Get your own version badge on microbadger.com")

Lidarr with a script to automatically convert FLAC files to 320Kbps MP3s. MP3s are fully tagged by ffmpeg.

# First Things First

Configure the container with all the port, volume, and environment settings from the original container documentation here:  
**[linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)**

## Usage

After all of the above configuration is complete, to use ffmpeg, configure a custom script from the Settings->Connect screen to call:

**`/usr/local/bin/flac2mp3.sh`**

It currently accepts no arguments.

**NOTE:** The original audio files will be deleted and permanently lost.

Only events/notification triggers that have been tested are **On Release Import** and **On Upgrade**

### Example
![lidarr-flac2mp3](https://raw.githubusercontent.com/TheCaptain989/lidarr-flac2mp3/master/images/flac2mp3.png)

### Logs

A new log file is created for the script activity called:

`/config/logs/flac2mp3.txt`

This log can be inspected from the GUI under System->Log Files

## Credits

This would not be possible without the following:

[Lidarr](https://lidarr.audio/)

[LinuxServer.io Lidarr](https://hub.docker.com/r/linuxserver/lidarr) container

[ffmpeg](https://ffmpeg.org/)

[![](https://images.microbadger.com/badges/image/thecaptain989/lidarr.svg)](https://microbadger.com/images/thecaptain989/lidarr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/thecaptain989/lidarr.svg)](https://microbadger.com/images/thecaptain989/lidarr "Get your own version badge on microbadger.com")

A Lidarr Docker container with a script to automatically convert downloaded FLAC files to MP3s using ffmpeg.  Default quality is 320Kbps.

# First Things First
Configure the Docker container with all the port, volume, and environment settings from the original container documentation here:  
**[linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr "Docker container")**

This container supports Linux OSes only.

## Usage
After all of the above configuration is complete, to use ffmpeg, configure a custom script from the Settings->Connect screen and type the following in the **Path** field:

**`/usr/local/bin/flac2mp3.sh`**

New track file(s) with an MP3 extension will be placed in the same directory as the original FLAC file(s). Existing MP3 files with the same track name will be overwritten.

If you've configured the Lidarr Recycle Bin path correctly, the original video will be moved there.  
**NOTE:** If you have *not* configured the Recycle Bin, the original FLAC audio file(s) will be deleted and permanently lost.

### Syntax
**Note:** The **Arguments** field for Custom Scripts was removed in Lidarr release [v0.7.0.1347](https://github.com/lidarr/Lidarr/commit/b9d240924f8965ebb2c5e307e36b810ae076101e "Lidarr commit notes") due to security concerns.
To support options with this version and later, a wrapper script can be manually created that will call *flac2mp3.sh* with the required arguments. Therefore, this section is for legacy and advanced purposes only.

The script accepts two options which may be placed in the **Arguments** field:

`[-d] [-b <bitrate>]`

The `-b bitrate` option, if specified, sets the output quality in bits per second.  If no `-b` option is specified, the script will default to 320Kbps.

The `-d` option enables debug logging.

#### Examples
```
-b 320k        # Output 320 kilobits per second MP3 (same as default behavior)
-d -b 160k     # Enable debugging, and output 160 kilobits per second MP3
```

#### Example Wrapper Script
To use the example options above, create and save the following text in a file called `wrapper.sh` and then use that in the **Path** field in place of `flac2mp3.sh` mentioned in the [Usage](./README.md#usage) section above.
```
#!/bin/bash

. /usr/local/bin/flac2mp3.sh -d -b 160k
```

#### Included Wrapper Script
An wrapper script to enable debugging is included in the Docker container.  
Use this script in place of the `flac2mp3.sh` mentioned in the [Usage](./README.md#usage) section above.

**`/usr/local/bin/flac2mp3-debug.sh`**

### Triggers
The only events/notification triggers that have been tested are **On Release Import** and **On Upgrade**

![lidarr-flac2mp3](https://raw.githubusercontent.com/TheCaptain989/lidarr-flac2mp3/master/images/flac2mp3.png "Lidarr Custom Script dialog")

### Logs
A log file is created for the script activity called:

`/config/logs/flac2mp3.txt`

This log can be downlaoded from the Lidarr GUI under System->Log Files

Log rotation is performed, with 5 log files of 1MB each kept, matching Lidarr's log retention.

If debug logging is enabled, the log file can grow very large very quickly.

## Credits
This would not be possible without the following:

[Lidarr](https://lidarr.audio/ "Lidarr homepage")

[LinuxServer.io Lidarr](https://hub.docker.com/r/linuxserver/lidarr "Docker container") container

[ffmpeg](https://ffmpeg.org/ "FFMpeg homepage")

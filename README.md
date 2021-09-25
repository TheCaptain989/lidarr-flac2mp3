# Development Repository
This is a development and test repo.  Visit the [production repository and branch](https://github.com/linuxserver/docker-mods/tree/lidarr-flac2mp3) for stable/production releases.

# About
A [Docker Mod](https://github.com/linuxserver/docker-mods) for the LinuxServer.io Lidarr Docker container that uses ffmpeg and a script to automatically convert downloaded FLAC files to MP3s.  Default output quality is 320Kbps constant bit rate.
Advanced options act as a light wrapper to ffmpeg, allowing conversion to any supported audio format, including AAC, AC3, and Opus.

>**NOTE:** This mod supports Linux OSes only.

Development Container info:
![Docker Image Size](https://img.shields.io/docker/image-size/thecaptain989/lidarr-flac2mp3 "Container Size")
![Docker Pulls](https://img.shields.io/docker/pulls/thecaptain989/lidarr-flac2mp3 "Container Pulls")  
Production Container info: ![Docker Image Size](https://img.shields.io/docker/image-size/linuxserver/mods/lidarr-flac2mp3 "Container Size")

# Installation
1. Pull the [linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr "LinuxServer.io's Lidarr container") docker image from Docker Hub:  
  `docker pull linuxserver/lidarr:latest`

2. Configure the Docker container with all the port, volume, and environment settings from the *original container documentation* here:  
  **[linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr "Docker container")**
   1. Add a **DOCKER_MODS** environment variable to the `docker run` command, as follows:  
      - Dev/test release: `-e DOCKER_MODS=thecaptain989/lidarr-flac2mp3:latest`  
      - Stable release: `-e DOCKER_MODS=linuxserver/mods:lidarr-flac2mp3`

      *Example Docker CLI Configuration*  
       ```shell
       docker run -d \
         --name=lidarr \
         -e PUID=1000 \
         -e PGID=1000 \
         -e TZ=America/Chicago \
         -e DOCKER_MODS=linuxserver/mods:lidarr-flac2mp3 \
         -p 8686:8686 \
         -v /path/to/appdata/config:/config \
         -v /path/to/music:/music \
         -v /path/to/downloads:/downloads \
         --restart unless-stopped \
         ghcr.io/linuxserver/lidarr
       ```   

      *Example Synology Configuration*  
      ![flac2mp3](.assets/lidarr-synology.png "Synology container settings")

   2. Start the container.

3. After the above configuration is complete, to use ffmpeg, configure a custom script from Lidarr's *Settings* > *Connect* screen and type the following in the **Path** field:  
   `/usr/local/bin/flac2mp3.sh`

   *Example*  
   ![lidarr-flac2mp3](.assets/lidarr-custom-script.png "Lidarr Custom Script dialog")

   This will use the defaults to create a 320Kbps MP3 file.

   *For any other setting, you **must** either use one of the [included wrapper scripts](./README.md#included-wrapper-scripts) or create a custom script with the command line options you desire.  See the [Syntax](./README.md#syntax) section below.*

## Usage
New file(s) with an MP3 extension will be placed in the same directory as the original FLAC file(s) and have the same owner and permissions. Existing MP3 files with the same track name will be overwritten.

If you've configured Lidarr's **Recycle Bin** path correctly, the original audio file will be moved there.  
![danger] **NOTE:** If you have *not* configured the Recycle Bin, the original FLAC audio file(s) will be deleted and permanently lost.

### Syntax
>**Note:** The **Arguments** field for Custom Scripts was removed in Lidarr release [v0.7.0.1347](https://github.com/lidarr/Lidarr/commit/b9d240924f8965ebb2c5e307e36b810ae076101e "Lidarr commit notes") due to security concerns.
To support options with this version and later, a wrapper script can be manually created that will call *flac2mp3.sh* with the required arguments.

The script accepts five command line options:

`[-d] [-b <bitrate> | -v <quality> | -a "<options>" -e <extension>]`

The `-b bitrate` option sets the output quality in constant bits per second (CBR).

The `-v quality` option sets the output quality using a variable bit rate (VBR) where `quality` is a value between 0 and 9, with 0 being the highest quality.  
See the [FFmpeg MP3 Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/MP3) for more details.  

The `-a "options"` setting is used in conjunction with `-e` to set advanced ffmpeg options.  The specified command line options replace all script defaults and are sent directly to ffmpeg.  The `options` value must be enclosed in quotes.  
![danger] **WARNING:** When using `-a`, you must specify an audio codec (via `-c:a`) or the resulting file will contain no audio.  
![danger] **WARNING:** Invalid `options` could result in script failure!  
See [FFmpeg Options](https://ffmpeg.org/ffmpeg.html#Options) for details on valid options.  
See [Guidelines for high quality audio encoding](https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio) for more information.

The `-e extension` option sets the output file extension, and must be used in conjunction with `-a`.  The `extension` may be prefixed by a dot (".") or not.

If neither `-b`, `-v`, `-a`, or `-e` options are specified, the script will default to a constant 320Kbps MP3.

The `-d` option enables debug logging.

#### Technical notes on `-a` advanced options
The `-a` option effectively makes the script a somewhat generic wrapper for ffmpeg.  FFmpeg is executed once per track with only the loglevel, input filename, and output filename being set.  All other options are passed unparsed to the command line.  

The exact format of the executed ffmpeg command is:
```
ffmpeg -loglevel error -i "Original.flac" ${Options} "NewTrack${Extension}"
```

### Examples
```
-b 320k        # Output 320 kbit/s MP3 (non VBR; same as default behavior)
-v 0           # Output variable bitrate MP3, VBR 220-260 kbit/s
-d -b 160k     # Enable debugging, and output a 160 kbit/s MP3
-a "-vn -c:a libopus -b:a 192K" -e .opus     # Convert to Opus format, VBR 192 kbit/s, no cover art
-a "-y -map 0 -c:a aac -b:a 240K -c:v copy" -e mp4     # Convert to MP4 format, using AAC 240 kbit/s audio, cover art, overwrite file
```

### Included Wrapper Scripts
For your convenience, several wrapper scripts are included in the `/usr/local/bin/` directory.  
You may use any of these scripts in place of the `flac2mp3.sh` mentioned in the [Installation](./README.md#installation) section above.

```
flac2mp3-debug.sh        # Enable debugging
flac2mp3-vbr.sh          # Use variable bit rate MP3, quality 0
flac2opus.sh             # Convert to Opus format using .opus extension
```

### Example Wrapper Script
To configure the middle entry from the [Examples](./README.md#examples) section above, create and save a file called `flac2mp3-custom.sh` to `/config` containing the following text:
```shell
#!/bin/bash

. /usr/local/bin/flac2mp3.sh -d -b 160k
```
Make it executable:
```shell
chmod +x /config/flac2mp3-custom.sh
```

Then put `/config/flac2mp3-custom.sh` in the **Path** field in place of `/usr/local/bin/flac2mp3.sh` mentioned in the [Installation](./README.md#installation) section above.

>**Note:** If you followed the Linuxserver.io recommendations when configuring your container, the `/config` directory will be mapped to an external storage location.  It is therefore recommended to place custom scripts in the `/config` directory so they will survive container updates, but they may be placed anywhere that is accessible by Lidarr.

### Triggers
The only events/notification triggers that have been tested are **On Release Import** and **On Upgrade**

### Logs
A log file is created for the script activity called:

`/config/logs/flac2mp3.txt`

This log can be downloaded from Lidarr under *System* > *Log Files*

Log rotation is performed, with 5 log files of 1MB each kept, matching Lidarr's log retention.
>![danger] **NOTE:** If debug logging is enabled, the log file can grow very large very quickly.  *Do not leave debug logging enabled permanently.*

## Credits
This would not be possible without the following:

[Lidarr](https://lidarr.audio/ "Lidarr homepage")  
[LinuxServer.io Lidarr](https://hub.docker.com/r/linuxserver/lidarr "Lidarr Docker container") container  
[LinuxServer.io Docker Mods](https://hub.docker.com/r/linuxserver/mods "Docker Mods containers") project  
[ffmpeg](https://ffmpeg.org/ "FFmpeg homepage")  
Icons made by [Freepik](https://www.freepik.com) from [Flaticon](https://www.flaticon.com/)

[warning]: .assets/warning.png "Warning"
[danger]: .assets/danger.png "Danger"

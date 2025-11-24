#!/bin/bash
# shellcheck disable=SC2181

container_name="lidarr"
repo="lidarr-flac2mp3"
status="$(docker ps -a --filter "name=^${container_name}$" --format '{{.Status}}')"

# Create lidarr container
if [ -z "$status" ]; then
 echo "Creating $container_name container"
 docker run -d -e TZ=America/Chicago --user root --name $container_name -p 8686:8686 -v /workspaces/$repo:/workspaces/$repo linuxserver/$container_name:latest
 if [ $? -ne 0 ]; then
   echo "Failed to start $container_name container"
   exit 1
 fi
elif [[ "$status" =~ Exited ]]; then
 echo "Starting existing $container_name container"
 docker start $container_name
 if [ $? -ne 0 ]; then
   echo "Failed to start $container_name container"
   exit 1
 fi
fi

# Install mkvmerge and bash-unit
if [ ! -f /workspaces/$repo/bash_unit ] && [ ! -f /usr/bin/ffmpeg ]; then
  echo "Installing ffmpeg and bash-unit in $container_name container"
  docker exec -it $container_name /bin/bash -c "cd /workspaces/$repo && apk add --no-cache ffmpeg && curl -s https://raw.githubusercontent.com/bash-unit/bash_unit/main/install.sh | bash"
  if [ $? -ne 0 ]; then
    echo "Failed to install bash-unit in $container_name container"
    exit 1
  fi
fi

# Run tests
docker exec -it $container_name /bin/bash -c "FORCE_COLOR=true /workspaces/$repo/bash_unit ${2} /workspaces/$repo/.github/tests/test_${1}*"
if [ $? -ne 0 ]; then
  echo "Tests failed"
  exit 1
fi
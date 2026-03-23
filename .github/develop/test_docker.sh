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

# Install ffmpeg and bash-unit
docker exec $container_name /bin/bash -c "test -f /tmp/bash_unit"
bashunit_installed=$?
docker exec $container_name /bin/bash -c "test -f /usr/bin/ffmpeg"
ffmpeg_installed=$?
if [ $bashunit_installed -ne 0 -o $ffmpeg_installed -ne 0 ]; then
  echo "Installing ffmpeg and bash-unit in $container_name container"
  docker exec -it $container_name /bin/bash -c "cd /tmp && apk add --no-cache ffmpeg && curl -s https://raw.githubusercontent.com/bash-unit/bash_unit/main/install.sh | bash"
  if [ $? -ne 0 ]; then
    echo "Failed to install bash-unit in $container_name container"
    exit 1
  fi
fi

# Checking that Lidarr is up and running before proceeding with tests
echo "Waiting for $container_name to start..."
until curl -s -I http://localhost:8686/ping > /dev/null; do
  sleep 2
done
echo "$container_name is up and running!"

# Run tests
docker exec -it $container_name /bin/bash -c "FORCE_COLOR=true /tmp/bash_unit ${2} /workspaces/$repo/.github/tests/test_${1}*"
if [ $? -ne 0 ]; then
  echo "Tests failed"
  exit 1
fi
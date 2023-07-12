#!/usr/bin/env -S -- bash

if (($#)); then
  export -- DOCKER_HOST="tcp://$1:${2:-2375}"
else
  export -- DOCKER_HOST='unix:///var/run/docker.sock'
fi
printf -- '%s\n' "DOCKER_HOST=$DOCKER_HOST"

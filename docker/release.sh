#!/usr/bin/env bash

set -eu
set -o pipefail


cd "$(dirname "$0")/.." || exit 1


IMAGE='msjpq/cli'
docker build -f 'docker/Dockerfile' -t "$IMAGE" .


if [[ $# -gt 1 ]]
then
  docker push "$IMAGE"
fi

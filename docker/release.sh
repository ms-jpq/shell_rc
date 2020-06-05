#!/usr/bin/env bash

set -eu
set -o pipefail

cd "$(dirname "$0")/.."

IMAGE="msjpq/cli"

docker build -t "$IMAGE" . -f "docker/Dockerfile"


if [[ $# -gt 1 ]]
then
  docker push "$IMAGE"
fi

#!/usr/bin/env bash

set -eu
set -o pipefail

cd "$(dirname "$0")"

IMAGE="msjpq/env"

docker build -t "$IMAGE" . -f "Dockerfile"


if [[ $# -gt 1 ]]
then
  docker push "$IMAGE"
fi

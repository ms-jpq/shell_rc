#!/usr/bin/env bash

set -Eeu
set -o pipefail
shopt -s globstar nullglob


cd -- "$(dirname -- "$0")/../.." || exit 1

TAG='windows-ansible'

docker buildx build --file ./docker/nt/Dockerfile --tag "$TAG"

#!/usr/bin/env bash

set -Eeu
set -o pipefail
shopt -s globstar nullglob


cd -- "$(dirname -- "$0")/../.." || exit 1

TAG='windows-ansible'

rm -f -- ./id_rsa*
ssh-keygen -q -N '' -f ./id_rsa
chmod 600 -- ./id_rsa*
docker build --file ./docker/nt/Dockerfile --tag "$TAG" -- .

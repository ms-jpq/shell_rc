#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O failglob -O globstar

cd -- "$(dirname -- "$0")/../.."

TAG='windows-ansible'

rm -f -- ./id_rsa*
ssh-keygen -q -N '' -f ./id_rsa
chmod 600 -- ./id_rsa*
docker build --file ./docker/nt/Dockerfile --tag "$TAG" -- .

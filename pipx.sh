#!/usr/bin/env bash

set -eu
set -o pipefail

cd "$(dirname "$0")" || exit 1


readarray -d $'\n' -t REQUIREMENTS < 'requirements.txt'

pip3 install --upgrade -- pipx

for requirement in "${REQUIREMENTS[@]}"
do
  pipx install --force -- "$requirement"
done

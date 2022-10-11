#!/usr/bin/env bash

set -Eeu
set -o pipefail
shopt -s nullglob globstar

cd "$(dirname -- "$0")" || exit 1


readarray -d $'\n' -t REQUIREMENTS < "$XDG_CONFIG_HOME/requirements.txt"

python3 -m pip install --upgrade -- pipx

for requirement in "${REQUIREMENTS[@]}"
do
  python3 -m pipx install --force -- "$requirement"
done

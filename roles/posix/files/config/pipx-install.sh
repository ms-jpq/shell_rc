#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O failglob -O globstar

cd -- "$(dirname -- "$0")" 

readarray -d $'\n' -t -- REQUIREMENTS <"$XDG_CONFIG_HOME/requirements.txt"

python3 -m pip install --upgrade -- pipx

for requirement in "${REQUIREMENTS[@]}"; do
  python3 -m pipx install --force -- "$requirement"
done

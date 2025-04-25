#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
export -- ASDF_CONFIG_FILE="$XDG_CONFIG_HOME/asdf/rc.conf" ASDF_DATA_DIR="$HOME/.local/asdf"

path=(
  "$ASDF_DATA_DIR/shims"
  "${path[@]}"
)

export -- DOTNET_CLI_TELEMETRY_OPTOUT=1

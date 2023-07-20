#!/usr/bin/env -S -- bash

export -- ASDF_DATA_DIR="$HOME/.local/asdf"
path=(
  "$HOME/.local/opt/asdf/bin"
  "$ASDF_DATA_DIR/bin"
  "$ASDF_DATA_DIR/shims"
  "${path[@]}"
)

export -- DOTNET_CLI_TELEMETRY_OPTOUT=1

#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
export -- ASDF_DATA_DIR="$XDG_DATA_HOME/asdf"
pathprepend "$HOME/.local/opt/asdf/bin" "$ASDF_DATA_DIR/bin" "$ASDF_DATA_DIR/shims"

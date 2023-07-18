#!/usr/bin/env -S -- bash

export -- ASDF_DATA_DIR="$HOME/.local/asdf"
pathprepend "$HOME/.local/opt/asdf/bin" "$ASDF_DATA_DIR/bin" "$ASDF_DATA_DIR/shims"

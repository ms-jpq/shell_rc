#!/usr/bin/env -S -- bash

export -- ASDF_DATA_DIR="$XDG_DATA_HOME/asdf"
pathprepend "$ASDF_DATA_DIR/bin" "$ASDF_DATA_DIR/shims"
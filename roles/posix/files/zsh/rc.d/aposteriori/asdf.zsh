#!/usr/bin/env -S -- bash

#################### ########### ####################
#################### ASDF Region ####################
#################### ########### ####################

export -- ASDF_CONFIG_FILE="$XDG_CONFIG_HOME/asdfrc"
export -- ASDF_DATA_DIR="$XDG_DATA_HOME/asdf"
# shellcheck disable=SC1091
source -- "$ASDF_DATA_DIR/asdf.sh"

#!/usr/bin/env -S -- bash

export -- EDITOR="${EDITOR:-nvim}"
export -- VISUAL="$EDITOR"
export -- BROWSER="${BROWSER:-open}"

# shellcheck disable=2154
export -- INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

#!/usr/bin/env -S -- bash

[[ -z $PS1 ]] && return

# shellcheck disable=SC2034
readarray -t -d ':' -- path < <(printf -- '%s' "$PATH")

export -- SHELL="${COMSPEC:-"$BASH"}"

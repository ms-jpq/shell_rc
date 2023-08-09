#!/usr/bin/env -S -- bash

# shellcheck disable=SC2034
readarray -t -d ':' -- path < <(printf -- '%s' "$PATH")
export -- SHELL="$BASH"

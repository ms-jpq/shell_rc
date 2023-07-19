#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
fzf "${_fzf_preview[@]}" "$@"

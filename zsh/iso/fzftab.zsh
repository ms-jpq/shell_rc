#!/usr/bin/env -S -- bash

zstyle ':fzf-tab:*' fzf-flags '--no-color'

# shellcheck disable=SC1091
source -- "$HOME/.local/opt/fzf-tab/fzf-tab.zsh"

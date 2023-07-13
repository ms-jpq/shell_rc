#!/usr/bin/env -S -- bash

#################### ############## ####################
#################### FZF Tab Region ####################
#################### ############## ####################

zstyle ':fzf-tab:*' fzf-flags '--no-color'

# INTI #
# shellcheck disable=SC1091
source -- "$ZDOTDIR/../fzf-tab/fzf-tab.zsh"
# INIT #

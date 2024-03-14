#!/usr/bin/env -S -- bash

# Emacs
bindkey -e

bindkey -- '^[[1;3C' emacs-forward-word
bindkey -- '^[[1;3D' emacs-backward-word

bindkey -- '^[[1;9C' emacs-forward-word
bindkey -- '^[[1;9D' emacs-backward-word
# Emacs

# Bash
bindkey -- '\C-u' backward-kill-line

autoload -U -- edit-command-line
zle -N -- edit-command-line
bindkey -- '\C-x\C-e' edit-command-line
# Bash

# History Expansion
bindkey -- ' ' magic-space
# History Expansion

# Del key
bindkey -- '^[[3~' delete-char
# Del key

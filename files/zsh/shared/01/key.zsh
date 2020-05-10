#################### ############## ####################
#################### Keybind Region ####################
#################### ############## ####################

# Emacs
bindkey -e
# tmux
bindkey '^[[1;3C' emacs-forward-word
bindkey '^[[1;3D' emacs-backward-word
# iterm
bindkey '^[[C' emacs-forward-word
bindkey '^[[D' emacs-backward-word
# Emacs


# Edit current line
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line
# Edit current line


# History Expansion
bindkey ' ' magic-space
# History Expansion


# Del key
bindkey "^[[3~" delete-char
# Del key


#################### ########## ####################
#################### FZF Region ####################
#################### ########## ####################

FZF_COLOUR="--color=light \
            --color=bg+:#dfdfdf"

export FZF_DEFAULT_OPTS="$FZF_COLOUR \
                         --reverse \
                         --no-height \
                         --border \
                         --cycle \
                         --tabstop=2 \
                         --preview-window=right:wrap \
                         --bind=ctrl-space:toggle \
                         --bind=tab:down \
                         --bind=btab:up \
                         --bind=shift-down:toggle+down \
                         --bind=shift-up:toggle+up \
                         --bind=shift-left:preview-up \
                         --bind=shift-right:preview-down \
                         --bind=alt-a:select-all \
                         --bind=alt-l:deselect-all"

FZF_PREVIEW='preview {}'

export FZF_DEFAULT_COMMAND='fd --type file -type symlink'
FZF_COMPLETION_OPTS="--preview='$FZF_PREVIEW'"

export FZF_ALT_C_COMMAND='fd --print0 --no-ignore --type file -type symlink'
FZF_ALT_C_OPTS="$FZF_COMPLETION_OPTS --read0"

export FZF_CTRL_T_COMMAND='fd --print0'
FZF_CTRL_T_OPTS="$FZF_COMPLETION_OPTS --read0"


export FZF_TMUX_HEIGHT='100%'


alias f='fzf'
alias fp="fzf --preview='$FZF_PREVIEW'"


d() {
  local dest="$(FZF_DEFAULT_COMMAND='fd -0 -t d' fp --read0 -q "${*:-""}")"
  cd "$dest" || return 1
}


#################### ################ ####################
#################### Overwrite Region ####################
#################### ################ ####################

_fzf_compgen_path() {
  fd -t d -t f -t l "$1"
}


_fzf_compgen_dir() {
  fd -t d "$1"
}


# INTI #
source "$ZDOTDIR/fzf/shell/key-bindings.zsh"
source "$ZDOTDIR/fzf/shell/completion.zsh"
# INIT #

#################### ########## ####################
#################### ENV Region ####################
#################### ########## ####################

export PROMPT_EOL_MARK=""

export XDG_CONFIG_HOME="$HOME/.config"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"


#################### ############## ####################
#################### Options Region ####################
#################### ############## ####################


# CD
setopt auto_cd           # if cmd match folder, cd
setopt auto_pushd        # dirstack
setopt pushd_ignore_dups # dirstack no dup
setopt cd_silent         # dont print after cd
# CD


# Completions


# Completions


# Glob

# Glob 


# History
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data
# History

#

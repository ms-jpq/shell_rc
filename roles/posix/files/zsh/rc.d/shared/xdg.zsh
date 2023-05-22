#!/usr/bin/env -S -- bash

#################### ########## ####################
#################### XDG Region ####################
#################### ########## ####################

export -- GNUPGHOME="$XDG_DATA_HOME/gnupg"
export -- WGETRC="$XDG_CONFIG_HOME/wgetrc"

export -- PYTHONSTARTUP="$XDG_CONFIG_HOME/pythonrc.py"
export -- RUBY_DEBUG_HISTORY_FILE="$XDG_CACHE_HOME/rdbg_history"
export -- NODE_REPL_HISTORY="$XDG_CACHE_HOME/node_hist"
export -- NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npmrc"

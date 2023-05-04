#!/usr/bin/env -S -- bash

#################### ########## ####################
#################### XDG Region ####################
#################### ########## ####################

export -- WGETRC="$XDG_CONFIG_HOME/wgetrc"

export -- GNUPGHOME="$XDG_DATA_HOME/gnupg"

export -- NODE_REPL_HISTORY="$XDG_CACHE_HOME/node_hist"
export -- NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npmrc"

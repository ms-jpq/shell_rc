#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
export -- BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME/bundle"
export -- BUNDLE_USER_HOME="$XDG_CACHE_HOME/bundle"
export -- GNUPGHOME="$XDG_STATE_HOME/gnupg"
export -- NODE_REPL_HISTORY="$XDG_STATE_HOME/shell_history/node"
export -- NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/rc.conf"
export -- PIPX_HOME="$HOME/.local/opt/pipx"
export -- PSQL_HISTORY="$XDG_STATE_HOME/shell_history/psql"
export -- PYTHONSTARTUP="$XDG_CONFIG_HOME/python/rc.py"
export -- RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/rc.conf"
export -- RUBY_DEBUG_HISTORY_FILE="$XDG_STATE_HOME/shell_history/rdbg"
export -- SQLITE_HISTORY="$XDG_STATE_HOME/shell_history/sqlite"
export -- WGETRC="$XDG_CONFIG_HOME/wget/config"

#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
export -- NODE_REPL_HISTORY="$XDG_STATE_HOME/shell_history/node"
export -- PSQL_HISTORY="$XDG_STATE_HOME/shell_history/psql"
export -- REDISCLI_HISTFILE="$XDG_STATE_HOME/shell_history/redis"
export -- RUBY_DEBUG_HISTORY_FILE="$XDG_STATE_HOME/shell_history/rdbg"
export -- R_HISTFILE="$XDG_STATE_HOME/shell_history/r"
export -- SQLITE_HISTORY="$XDG_STATE_HOME/shell_history/sqlite"

export -- BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME/bundle"
export -- BUNDLE_USER_HOME="$XDG_CACHE_HOME/bundle"
export -- DOTNET_CLI_HOME="$XDG_CACHE_HOME/dotnet"
export -- GNUPGHOME="$XDG_STATE_HOME/gnupg"
export -- NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/rc.conf"
export -- NUGET_PACKAGES="$XDG_DATA_HOME/NuGet/packages"
export -- PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python"
export -- PYTHONSTARTUP="$XDG_CONFIG_HOME/python/rc.py"
export -- RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/rc.conf"
export -- RLWRAP_HOME="$XDG_STATE_HOME/rlwrap"
export -- WGETRC="$XDG_CONFIG_HOME/wget/config"
export -- TF_CLI_CONFIG_FILE="$XDG_CONFIG_HOME/terraform/config.tfrc"

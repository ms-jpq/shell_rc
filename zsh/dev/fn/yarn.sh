#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
npm exec --yes -- yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"

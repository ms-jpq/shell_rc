#!/usr/bin/env -S -- bash

brew update
brew upgrade
# shellcheck disable=SC2312
brew list --versions | awk -- '$2 ~ /^HEAD/ { print $1 }' | xargs -r -- brew upgrade --fetch-HEAD --
brew cleanup
brew doctor

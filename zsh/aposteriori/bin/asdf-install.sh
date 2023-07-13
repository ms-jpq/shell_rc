#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='gv:'
LONG_OPTS='global,version:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval set -- "$GO"

GLOBAL=0
VERSION=
LANG=
while true; do
  case "$1" in
  -g | --global)
    GLOBAL=1
    shift
    ;;
  -v | --version)
    VERSION="$2"
    shift -- 2
    ;;
  --)
    shift
    ;;
  *)
    LANG="$*"
    break
    ;;
  esac
done

if [[ -z "$LANG" ]]; then
  printf -- '%s\n' 'Please Enter a Langauge!'
  exit 2
fi

LIST="$(asdf plugin list)"
readarray -t -- PLUGINS <<<"$LIST"

PLUGIN_INSTALLED=0
for PLUGIN in "${PLUGINS[@]}"; do
  if [[ "$PLUGIN" = "$LANG" ]]; then
    PLUGIN_INSTALLED=1
    break
  fi
done

if ((PLUGIN_INSTALLED)); then
  asdf plugin update "$LANG"
else
  asdf plugin add "$LANG"
fi

LIST="$(asdf list "$LANG")"
readarray -t -- INSTALLED <<<"$LIST"

if [[ -z "$VERSION" ]]; then
  VERSION="$(asdf latest "$LANG")"
fi

VERSION_INSTALLED=0
for VER in "${INSTALLED[@]}"; do
  if [[ "$VER" = "$VERSION" ]]; then
    VERSION_INSTALLED=1
    break
  fi
done

if ! ((VERSION_INSTALLED)); then
  asdf install "$LANG" "$VERSION"
fi

if ((GLOBAL)); then
  asdf global "$LANG" "$VERSION"
fi

asdf reshim

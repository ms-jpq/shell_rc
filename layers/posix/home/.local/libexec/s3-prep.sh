#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ACTION="$1"
TMP="$2"
REMOTES="$TMP/git-remotes.txt"
shift -- 2

case "$OSTYPE" in
darwin*)
  DEV="$HOME/dev.localized"
  ;;
*)
  DEV="$HOME/dev"
  ;;
esac

case "$ACTION" in
push)
  for F in "$@"; do
    NAME="$TMP/~/$F"
    mkdir -v -p -- "${NAME%/*}"
    cp -v -R -- "$HOME/$F" "$NAME"
  done
  for F in "$DEV"/*/.git/; do
    F="${F%/*}"
    GIT="${F%/*}"
    if REMOTE="$(git -C "$F" remote | xargs -L 1 -- git -C "$F" remote get-url)"; then
      NAME="${GIT#"$DEV/"}"
      printf -- '%s\0' "$NAME#$REMOTE"
    fi
  done >"$REMOTES"

  find "$TMP" -type f -name '.gitignore' -delete
  find "$TMP" -type f -print0 | xargs -0 -- gpg --batch --yes --encrypt-files --
  find "$TMP" -type f -not -name '*.gpg' -delete
  ;;
pull)
  REL="$TMP/~"
  find "$REL" -type f -print0 | xargs -0 -- gpg --batch --yes --decrypt-files -- "$REMOTES.gpg"
  find "$REL" -type f -name '*.gpg' -delete

  for F in "$REL"/**/*; do
    NAME="$HOME${F#"$REL"}"
    if [[ -d "$F" ]]; then
      mkdir -v -p -- "$NAME"
    else
      mkdir -v -p -- "${NAME%/*}"
      mv -v -- "$F" "$NAME"
    fi
  done

  readarray -t -d $'\0' -- LINES <"$REMOTES"
  for LINE in "${LINES[@]}"; do
    NAME="$DEV/${LINE%%#*}"
    URL="${LINE#*#}"
    if ! [[ -d "$NAME" ]]; then
      printf -- '%s\0' "$URL" "$NAME"
    fi
  done | xargs -0 -n 2 -P 0 -- git clone --recurse-submodules --
  ;;
*)
  set -x
  exit 1
  ;;
esac

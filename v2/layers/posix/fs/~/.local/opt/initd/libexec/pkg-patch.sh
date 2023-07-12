#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "$HOME"

TXT="$(grep -- '^[^#]' ./.config/packages/*.txt)"
readarray -t -d $'\n' -- DESIRED <<<"$TXT"

case "$OSTYPE" in
darwin*)
  PKGS="$(brew list --formula -1)"
  ;;
linux*)
  PKGS="$(dpkg --get-selections | cut --field 1)"
  ;;
*)
  exit 1
  ;;
esac

readarray -t -d $'\n' -- INSTALLED <<<"$PKGS"

declare -A -- PRESENT=()

for PKG in "${INSTALLED[@]}"; do
  PRESENT["$PKG"]=1
done

ADD=()
RM=()

for LINE in "${DESIRED[@]}"; do
  ACTION="${LINE%% *}"
  PKG="${LINE##* }"

  case "$ACTION" in
  +)
    if [[ -z "${PRESENT["$PKG"]}" ]]; then
      ADD+=("$PKG")
    fi
    ;;
  -)
    if [[ -n "${PRESENT["$PKG"]}" ]]; then
      RM+=("$PKG")
    fi
    ;;
  *)
    exit 1
    ;;
  esac
done

if (("${#RM[@]}")); then
  case "$OSTYPE" in
  darwin*)
    brew uninstall -- "${RM[@]}"
    ;;
  linux*)
    apt-get purge --yes -- "${RM[@]}"
    ;;
  *)
    exit 1
    ;;
  esac
fi

if (("${#ADD[@]}")); then

  case "$OSTYPE" in
  darwin*)
    brew install -- "${ADD[@]}"
    ;;
  linux*)
    apt-get install --no-install-recommends --yes -- "${ADD[@]}"
    ;;
  *)
    exit 1
    ;;
  esac
fi

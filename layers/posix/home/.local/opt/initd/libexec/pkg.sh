#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

TXT="$(grep -E -h -- '^(\+|-) .+' ./packages/*.txt)"
readarray -t -d $'\n' -- DESIRED <<<"$TXT"

case "$OSTYPE" in
darwin*)
  PKGS="$(brew list --formula --full-name -1)"
  ;;
linux*)
  PKGS="$(dpkg --get-selections | cut --field 1)"
  ;;
*msys*)
  WG_JSON="$(mktemp)"
  winget.exe export --accept-source-agreements --output "$WG_JSON"
  PKGS="$(jq --exit-status --raw-output '.Sources[].Packages[].PackageIdentifier' "$WG_JSON")"
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
    if [[ -z "${PRESENT["$PKG"]:-""}" ]]; then
      ADD+=("$PKG")
    fi
    ;;
  -)
    if [[ -n "${PRESENT["$PKG"]:-""}" ]]; then
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
    sudo -- apt-get purge --yes -- "${RM[@]}"
    ;;
  *msys*)
    for DEL in "${RM[@]}"; do
      winget uninstall --accept-source-agreements --id "$DEL"
    done
    ;;
  *)
    exit 1
    ;;
  esac
fi

if (("${#ADD[@]}")); then
  case "$OSTYPE" in
  darwin*)
    brew install --formula -- "${ADD[@]}"
    ;;
  linux*)
    sudo -- apt-get update
    DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --no-install-recommends --yes -- "${ADD[@]}"
    ;;
  *msys*)
    for A in "${ADD[@]}"; do
      winget instal --accept-source-agreements --accept-package-agreements --exact --id "$A"
    done
    ;;
  *)
    exit 1
    ;;
  esac
fi

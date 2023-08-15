#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

TXT="$(grep -E -h -- '^(\+|-) .+' ./packages/*.txt)"
readarray -t -d $'\n' -- DESIRED <<<"$TXT"

case "$OSTYPE" in
darwin*)
  if ! command -v -- brew; then
    URI='https://raw.githubusercontent.com/Homebrew/install/master/install.sh'
    SH="$(curl --fail-with-body --location --no-progress-meter -- "$URI")"
    bash -c "$SH"
  fi
  PKGS="$(brew list --formula --full-name -1)"
  ;;
linux*)
  PKGS="$(dpkg --get-selections | cut --field 1)"
  ;;
msys)
  WG_JSON="$(mktemp)"
  winget export --disable-interactivity --accept-source-agreements --output "$WG_JSON"
  PKGS="$(jq --exit-status --raw-output '.Sources[].Packages[].PackageIdentifier' "$WG_JSON" | tr --delete '\r')"
  rm -fr -- "$WG_JSON"
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
  PKG="${LINE#* }"

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
    printf -- '%s%q\n' '>! ' "$LINE" >&2
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
  msys)
    for DEL in "${RM[@]}"; do
      printf -- '%s%q\n' '> --id ' "$DEL" >&2
      winget uninstall --disable-interactivity --accept-source-agreements --id "$DEL"
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
  msys)
    WINGET=(
      winget install
      --disable-interactivity
      --accept-source-agreements --accept-package-agreements
      --exact
      --id
    )
    for A in "${ADD[@]}"; do
      printf -- '%s%q\n' '> --id ' "$A" >&2
      "${WINGET[@]}" "$A"
    done
    ;;
  *)
    exit 1
    ;;
  esac
fi

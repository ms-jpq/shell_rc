#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

TXT="$(sed -E -ne '/^[+-]/p' -- /dev/null ./packages/*.txt)"
readarray -t -- DESIRED < <(printf -- '%s' "$TXT")

case "$OSTYPE" in
darwin*)
  if ! command -v -- brew; then
    URI='https://raw.githubusercontent.com/Homebrew/install/master/install.sh'
    SH="$(curl --fail --location --no-progress-meter -- "$URI")"
    bash -c "$SH"
  fi
  PKGS="$(brew list --formula --full-name -1)"
  ;;
linux*)
  PKGS="$(dpkg --get-selections | cut --field 1 | cut --delimiter : --field 1)"
  ;;
msys | cygwin)
  PKGS_JSON="$(mktemp)"
  trap 'rm -f -- "$PKGS_JSON"' EXIT
  winget export --disable-interactivity --accept-source-agreements --output "$PKGS_JSON"
  PKGS="$(jq --raw-output '.Sources[].Packages[].PackageIdentifier' "$PKGS_JSON")"
  ;;
*)
  exit 1
  ;;
esac

readarray -t -- INSTALLED < <(printf -- '%s' "$PKGS")

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
    if [[ -z ${PRESENT["$PKG"]:-} ]]; then
      ADD+=("$PKG")
    fi
    ;;
  -)
    if [[ -n ${PRESENT["$PKG"]:-} ]]; then
      RM+=("$PKG")
    fi
    ;;
  *)
    printf -- '%s%s\n' '>! ' "${LINE@Q}" >&2
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
    sudo -- apt-get autoremove --yes
    ;;
  msys | cygwin)
    WINGET=(
      winget uninstall
      --disable-interactivity
      --accept-source-agreements
      --id
    )
    for DEL in "${RM[@]}"; do
      printf -- '%s%s\n' '> --id ' "${DEL@Q}" >&2
      "${WINGET[@]}" "$DEL"
    done
    ;;
  *)
    exit 1
    ;;
  esac
fi

if (("${#ADD[@]}")); then
  printf -- '%s\n' "${ADD[@]@Q}" >&2
  case "$OSTYPE" in
  darwin*)
    if [[ -z ${CI:-} ]]; then
      brew update
      brew upgrade
    fi
    brew install --formula -- "${ADD[@]}"
    if [[ -z ${CI:-} ]]; then
      brew cleanup
    fi
    ;;
  linux*)
    sudo -- apt-get update
    sudo -- env -- DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes
    sudo -- env -- DEBIAN_FRONTEND=noninteractive apt-get install --yes -- "${ADD[@]}" < /dev/null
    sudo -- apt-get autoremove --yes
    sudo -- apt-get clean
    ;;
  msys | cygwin)
    WINGET=(
      winget install
      --source winget
      --no-upgrade
      --disable-interactivity
      --accept-source-agreements --accept-package-agreements
      --exact
      --id
    )
    for A in "${ADD[@]}"; do
      printf -- '%s%s\n' '> --id ' "${A@Q}" >&2
      STATUS=0
      "${WINGET[@]}" "$A" || STATUS=$?
      if ((STATUS != 0 && STATUS != (0x8A150061 & 255))); then
        printf -- '%s%s\n' '!!! --id ' "${A@Q}" >&2
        exit 1
      fi
    done
    ;;
  *)
    exit 1
    ;;
  esac
fi

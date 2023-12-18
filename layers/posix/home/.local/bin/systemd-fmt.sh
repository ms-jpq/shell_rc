#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

fmt() {
  readarray -t -- LINES

  MAX=0
  for LINE in "${LINES[@]}"; do
    if [[ "$LINE" =~ ^[[:space:]]*#.*$ ]]; then
      :
    elif [[ "$LINE" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]*=.*$ ]]; then
      M="${#BASH_REMATCH[1]}"
      MAX=$((M > MAX ? M : MAX))
    fi
  done

  SKIP=0
  for LINE in "${LINES[@]}"; do
    if ((SKIP)); then

      case "$LINE" in
      *\\\\)
        SKIP=0
        ;;
      *\\)
        SKIP=1
        ;;
      *)
        SKIP=0
        ;;
      esac

      printf -- '%s\n' "$LINE"
    elif [[ "$LINE" =~ ^[[:space:]]*#[[:space:]]*(.*)$ ]]; then
      printf -- '%s\n' "# ${BASH_REMATCH[1]}"
    elif [[ "$LINE" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      L="${#BASH_REMATCH[1]}"
      RHS="${BASH_REMATCH[2]}"

      RHS="${RHS%"${RHS##*[![:space:]]}"}"

      case "$RHS" in
      *\\\\) ;;
      *\\)
        SKIP=1
        ;;
      *) ;;
      esac

      if [[ -n "$RHS" ]]; then
        RHS=" $RHS"
      fi

      M=$((MAX - L))
      P=" "
      for ((i = 0; i < M; i++)); do
        P="$P "
      done

      printf -- '%s\n' "${BASH_REMATCH[1]}${P}=${RHS}"
    elif [[ "$LINE" =~ ^[[:space:]]*([^[:space:]]*)[[:space:]]*$ ]]; then
      printf -- '%s\n' "${BASH_REMATCH[1]}"
    else
      printf -- '%s\n' "??? --> $LINE" >&2
      exit 1
    fi
  done
}

if [[ "${SYSTEMD_FMT_MODE:-""}" == 'stream' ]]; then
  declare -A -- SEEN=()
  TMP="$(mktemp)"

  while read -r -d '' -- FILE; do
    if [[ -L "$FILE" ]]; then
      FILE="$(realpath -- "$FILE")"
    fi
    if [[ -v SEEN["$FILE"] ]]; then
      continue
    fi
    SEEN["$FILE"]=1

    printf -- '%q\n' "$FILE" >&2
    SYSTEMD_FMT_MODE='' fmt <"$FILE" >"$TMP"
    mv -f -- "$TMP" "$FILE"
  done
elif (($#)); then
  readarray -t -- IS <<<"${SYSTEMD_FMT_IGNORE:-""}"
  declare -A -- IGNORE=()
  for I in "${IS[@]}"; do
    if [[ -n "$I" ]]; then
      IGNORE["$I"]=1
    fi
  done

  for FILE in "$@"; do
    if [[ -d "$FILE" ]]; then
      for F in "$FILE"/**/{*.link,*.netdev,*.network,*.socket,*.service,*.target,*.mount,*.automount,*.dnssd,*/*.network.d/*.conf,*/repart.d/*.conf,*/systemd/**/*.conf}; do
        if [[ -f "$F" ]] && [[ -z "${IGNORE["$F"]:-""}" ]]; then
          printf -- '%s\0' "$F"
        fi
      done
    else
      printf -- '%s\0' "$FILE"
    fi
  done | SYSTEMD_FMT_MODE='stream' "$0"
elif [[ -t 0 ]]; then
  exec -- "$0" .
else
  fmt
fi

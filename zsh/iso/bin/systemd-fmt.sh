#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

if (($#)); then
  TMP="$(mktemp)"
  for FILE in "$@"; do
    if [[ -d "$FILE" ]]; then
      SYSTEMD_FMT_GLOB="$FILE" "$0"
    else
      printf -- '%s\n' "$FILE" >&2
      "$0" <"$FILE" >"$TMP"
      mv -f -- "$TMP" "$FILE"
    fi
  done
elif [[ -t 0 ]] || [[ -v SYSTEMD_FMT_GLOB ]]; then
  TMP="$(mktemp)"
  DIR="${SYSTEMD_FMT_GLOB:-"."}"
  unset -- SYSTEMD_FMT_GLOB
  for FILE in "$DIR"/**/{*.link,*.netdev,*.network,*.socket,*.service,*/repart.d/*.conf,*/systemd/**/*.conf}; do
    printf -- '%s\n' "$FILE" >&2
    "$0" <"$FILE" >"$TMP"
    mv -f -- "$TMP" "$FILE"
  done
else
  readarray -t -d $'\n' -- LINES

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
      printf -- '%s\n' "unexpected --> $LINE" >&2
      exit 1
    fi
  done
fi

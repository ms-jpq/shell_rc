#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

fmt() {
  readarray -t -- LINES

  MAX=0
  for LINE in "${LINES[@]}"; do
    if [[ $LINE =~ ^[[:space:]]*#.*$ ]]; then
      :
    elif [[ $LINE =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]*=.*$ ]]; then
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
    elif [[ $LINE =~ ^[[:space:]]*#[[:space:]]*(.*)$ ]]; then
      printf -- '%s\n' "# ${BASH_REMATCH[1]}"
    elif [[ $LINE =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
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

      if [[ -n $RHS ]]; then
        RHS=" $RHS"
      fi

      M=$((MAX - L))
      P=" "
      for ((i = 0; i < M; i++)); do
        P="$P "
      done

      printf -- '%s\n' "${BASH_REMATCH[1]}${P}=${RHS}"
    elif [[ $LINE =~ ^[[:space:]]*([^[:space:]]*)[[:space:]]*$ ]]; then
      printf -- '%s\n' "${BASH_REMATCH[1]}"
    else
      printf -- '%s\n' "??? --> $LINE" >&2
      exit 1
    fi
  done
}

if [[ ${SYSTEMD_FMT_MODE:-""} == 'stream' ]]; then
  FILE="$*"
  TMP="$(mktemp)"
  printf -- '%q\n' "$FILE" >&2
  fmt < "$FILE" > "$TMP"
  mv -f -- "$TMP" "$FILE"
elif (($#)); then
  readarray -t -- IS <<< "${SYSTEMD_FMT_IGNORE:-""}"

  declare -A -- SEEN=()
  for I in "${IS[@]}"; do
    if [[ -n $I ]]; then
      if I="$(realpath -- "$I" 2> /dev/null)"; then
        SEEN["$I"]=1
      fi
    fi
  done

  unseen() {
    local F="$*"
    if F="$(realpath -- "$F" 2> /dev/null)"; then
      if [[ -f $F ]] && [[ -z ${SEEN["$F"]:-""} ]]; then
        SEEN["$F"]=1
        printf -- '%s\0' "$F"
      fi
    fi
  }

  for FILE in "$@"; do
    if [[ -d $FILE ]]; then
      for F in "$FILE"/**/{*.link,*.netdev,*.network,*.socket,*.service,*.target,*.mount,*.automount,*.dnssd,*/*.network.d/*.conf,*/repart.d/*.conf,*/systemd/**/*.conf}; do
        unseen "$F"
      done
    else
      unseen "$FILE"
    fi
  done | SYSTEMD_FMT_MODE='stream' xargs -r -0 -n 1 -P 0 -- "$0"
elif [[ -t 0 ]]; then
  exec -- "$0" .
else
  fmt
fi

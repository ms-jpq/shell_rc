#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='f:'
LONG_OPTS='font:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

while (($#)); do
  case "$1" in
  -f | --font)
    FONT="$2"
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    exit 1
    ;;
  esac
done

TTL="$1"
NOW="$(date -- '+%s')"
END=$((TTL * 60 + NOW))

if ! [[ -v FONT ]]; then
  FONT="$(SHOW_FONT=1 "${0%/*}/big")"
fi
CLS="$(clear)"

colour() {
  if command -v -- gay &>/dev/null; then
    gay
  else
    tee
  fi
}

fig() {
  # shellcheck disable=SC2154
  HR="$("$XDG_CONFIG_HOME/zsh/libexec/hr.sh")"

  FIG="$HR$(figlet -c -w "$COLS" -f "$FONT" -- "$*")"
  readarray -t -- L <<<"$FIG"
  LS="${#L[@]}"

  P=$(((LINES - LS - 1) / 2))

  PAD=()
  for ((i = 0; i < P; i++)); do
    PAD+=($'\n')
  done

  CLS_LINE="$CLS$(printf -- '%s\n%s' "${PAD[*]}$FIG" "$HR" | colour)"
  printf -- '%s' "$CLS_LINE"
}

while true; do
  NOW="$(date -- '+%s')"
  if ((NOW <= END)); then
    TIME="$(date --utc --date="@$((END - NOW))" -- '+%H:%M:%S')"
    LINES="$(tput -- lines)"
    COLS="$(tput -- cols)"
    fig "$TIME"
    sleep -- 1
  else
    fig "00:00:00"
    break
  fi
done

notify() {
  if command -v -- osascript &>/dev/null; then
    osascript -e 'display notification "🍅🍅🍅" with title "🥫" sound name "Frog"'
  else
    :
  fi
}

while true; do
  notify
  sleep -- 1
done

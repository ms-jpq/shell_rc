#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TTL="$1"
NOW="$(date -- '+%s')"
END=$((TTL * 60 + NOW))

FONT="$(SHOW_FONT=1 big)"
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
  readarray -t -d $'\n' -- L <<<"$FIG"
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

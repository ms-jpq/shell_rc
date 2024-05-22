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
    TTL="$2"
    shift -- 2
    break
    ;;
  *)
    exit 1
    ;;
  esac
done

NOW="${EPOCHREALTIME%%.*}"
END=$((TTL * 60 + NOW))

# Legible fonts
_=(
  big
  doom
  epic
  larry3d
  nancyj
  ogre
  pawp
  puffy
  rounded
  starwars
  tinker-toy
)

export -- TERM=xterm-256color

if ! [[ -v FONT ]]; then
  FONTS=("$(figlet -I 2)"/**.flf)
  FONT="$(printf -- '%s\0' "${FONTS[@]}" | fzf --read0)"
fi
CLS="$(clear)"

colour() {
  if command -v -- gay &> /dev/null; then
    gay
  else
    tee
  fi
}

fig() {
  # shellcheck disable=SC2154
  HR="$("$XDG_CONFIG_HOME/zsh/libexec/hr.sh")"

  FIG="$HR$(figlet -c -w "$COLS" -f "$FONT" -- "$*")"
  readarray -t -- L <<< "$FIG"
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
  NOW="${EPOCHREALTIME%%.*}"
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

while true; do
  case "$OSTYPE" in
  darwin*)
    BODY="$(fortune | tr -- '\n' ' ' | sed -E -e 's/[[:space:]]+/ /g')"
    senpai.js '🥫🥫' "$BODY"
    ;;
  *)
    set -x
    ;;
  esac
  sleep -- 1
done

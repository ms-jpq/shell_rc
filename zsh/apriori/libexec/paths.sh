#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
IFS=':'

print_err() {
  printf -- '%q' "$PATH"
  {
    printf -- 'paths {show, add, rm|remove} path\n'
    printf -- '%s\n' "$1"
  } >&2
  exit 1
}

remove() {
  local -- target="$1" slient="$2"

  local -- acc=()
  local -- arr
  read -d '' -r -a arr < <(printf -- '%s' "$PATH") || true
  for path in "${arr[@]}"; do
    if [[ "$path" != "$target" ]]; then
      acc+=("$path")
    fi
  done
  local -- ret="${acc[*]}"
  printf -- '%q' "$ret"

  if ! ((slient)); then
    printf -- '%s\n' "REMOVED -- $target" >&2
  fi
}

add() {
  local -- target="$1"
  local -- dedup

  if [[ -d "$target" ]]; then
    dedup="$target:$(remove "$target" 1)"
    printf -- '%q' "$dedup"
    printf -- '%s\n' "ADDED   -- $target" >&2
  else
    print_err "ERR! -- Not a Directory: $target"
  fi
}

ACTION="${1:-""}"
case "$ACTION" in
show)
  printf -- '%q' "$PATH"
  printf -- '%s' "$PATH" | awk -v 'RS=:' '!seen[$0]++' >&2
  ;;
add)
  P="${2:-"$PWD"}"
  target="$(realpath -- "${P%/}" || true)"
  add "$target"
  ;;
rm | remove)
  P="${2:-"$PWD"}"
  target="$(realpath -- "${P%/}" || true)"
  remove "$target" 0
  ;;
*)
  print_err 'ERR! -- Must be one of ^'
  ;;
esac

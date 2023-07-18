#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
IFS=':'

print_err() {
  printf -- '%q' "$PATH"
  printf >&2 -- 'paths {show, add, rm|remove} path\n'
  printf >&2 -- '%s\n' "$1"
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
    printf >&2 -- '%s\n' "REMOVED -- $target"
  fi
}

add() {
  local -- target="$1"
  local -- dedup

  if [[ -d "$target" ]]; then
    dedup="$target:$(remove "$target" 1)"
    printf -- '%q' "$dedup"
    printf >&2 -- '%s\n' "ADDED   -- $target"
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
  target="$(realpath -- "${2:-"$PWD"}")"
  add "$target"
  ;;
rm | remove)
  target="$(realpath -- "${2:-"$PWD"}")"
  remove "$target" 0
  ;;
*)
  print_err 'ERR! -- Must be one of ^'
  ;;
esac

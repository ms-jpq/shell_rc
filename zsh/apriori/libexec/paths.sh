#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARG_NUM=$#

print_path() {
  printf -- '%s' "$PATH"
}

print_err() {
  print_path
  printf >&2 -- 'paths {show, add, rm|remove, toggle} path\n'
  printf >&2 -- '%s\n' "$1"
  exit 1
}

check_arg() {
  if ((ARG_NUM != 2)); then
    print_err 'ERR! -- # of arguments'
  fi
}

show() {
  print_path
  print_path | awk -v 'RS=:' '!seen[$0]++' >&2
}

remove() {
  local -- target="$1"

  local -- acc=()
  local -- arr
  IFS=':' read -d '' -r -a arr < <(print_path) || true
  for path in "${arr[@]}"; do
    if [[ "$path" != "$target" ]]; then
      acc+=("$path")
    fi
  done
  IFS=':'
  local -- ret="${acc[*]}"
  unset -- IFS
  printf -- '%q' "$ret"

  printf >&2 -- '%s\n' "REMOVED -- $target"
}

add() {
  local -- target="$1"

  if [[ -d "$target" ]]; then
    printf -- '%q' "$target:$(remove "$target" 1)"
    printf >&2 -- '%s\n' "ADDED   -- $target"
  else
    print_err "ERR! -- Not a Directory: $target"
  fi
}

toggle() {
  local -- target="$1"

  local -- found=0
  local -- arr
  IFS=':' read -d '' -r -a arr < <(print_path) || true
  for path in "${arr[@]}"; do
    if [[ "$path" == "$target" ]]; then
      found=1
      break
    fi
  done

  if ((found)); then
    remove "$target"
  else
    add "$target"
  fi
}

if ! ((ARG_NUM)); then
  print_err 'ERR! -- # of arguments'
fi
ACTION="$1"
case "$ACTION" in
show)
  show
  ;;
add)
  check_arg
  target="$(realpath -- "$2")"
  add "$target"
  ;;
rm | remove)
  check_arg
  target="$(realpath -- "$2")"
  remove "$target"
  ;;
toggle)
  check_arg
  target="$(realpath -- "$2")"
  toggle "$target"
  ;;
*)
  print_err 'ERR! -- Must be one of ^'
  ;;
esac

#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

A0="$1"
ARGV=("$A0")
shift -- 1

case "$A0" in
m4)
  ARGV+=(--prefix-builtins)
  ;;
jq)
  ARGV+=(--null-input --sort-keys)
  ;;
awk | gawk)
  ARGV+=(-f -)
  ;;
sed)
  ARGV+=(-E -f -)
  ;;
perl)
  ARGV+=(-CASD -w)
  ;;
psql)
  ARGV+=(--no-password --single-transaction --expanded)
  ;;
node)
  ARGV+=(--input-type=module)
  ;;
clj)
  # shellcheck disable=SC2154
  M2="$XDG_CACHE_HOME/m2"
  M2="$(jq --exit-status --raw-input <<<"$M2")"
  ARGV+=(-Sdeps "{:mvn/local-repo $M2}")
  ;;
jshell)
  ARGV+=(-)
  ;;
*) ;;
esac

ARGV+=("$@")
read -r -d '' -- SCRIPT

{
  printf -- '\n>> '
  printf -- '%q ' "${ARGV[@]}"
  printf -- '\n'
  # shellcheck disable=SC2154
  "$XDG_CONFIG_HOME/zsh/libexec/hr.sh" '>'
} >&2
"${ARGV[@]}" <<<"$SCRIPT" || true
"$XDG_CONFIG_HOME/zsh/libexec/hr.sh" '<'

if [[ -t 1 ]]; then
  exec -- "$0" "$A0" "$@"
fi

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
  ARGV+=(--sort-keys --from-file /dev/fd/0)
  ;;
awk | gawk)
  ARGV+=(-f -)
  ;;
sed)
  ARGV+=(-E -f -)
  ;;
python*)
  export -- PYTHONSAFEPATH=1
  ;;
perl)
  ARGV+=(-CASD -w)
  ;;
sqlite3)
  ARGV+=(-bail)
  ;;
psql)
  ARGV+=(--no-password --single-transaction)
  if [[ -t 1 ]]; then
    ARGV+=(--expanded)
  else
    ARGV+=(--no-align --tuples-only)
  fi
  ;;
mysql)
  ARGV+=(--show-warnings --safe-updates --auto-vertical-output)
  ;;
node)
  ARGV+=(--input-type=module)
  ;;
pwsh)
  ARGV+=(-NoProfile -NonInteractive)
  ;;
osa)
  ARGV=(osascript -l JavaScript)
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

if [[ -t 1 ]]; then
  "${ARGV[@]}" <<<"$SCRIPT" || true
  "$XDG_CONFIG_HOME/zsh/libexec/hr.sh" '<' >&2
  exec -- "$0" "$A0" "$@"
else
  "${ARGV[@]}" <<<"$SCRIPT" | tee -- /dev/stderr
  "$XDG_CONFIG_HOME/zsh/libexec/hr.sh" '<' >&2
fi

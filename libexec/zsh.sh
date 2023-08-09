#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

OS="$1"
OUT="$2"
shift -- 2

FUNC="$OUT/fn"
BINS="$OUT/bin"
BLIB="$OUT/libexec"

rm -fr -- "$OUT"
mkdir -p -- "$FUNC" "$BINS" "$BLIB"

DIRS=(
  ./zsh/apriori
  ./zsh/{iso,tmux}
  ./zsh/"$OS"
  ./zsh/aposteriori
  ./zsh/{dev,fun,docker}
)

SH=()
ZSH=()
BSH=(./zsh/apriori.bash ./layers/posix/home/.zshenv)

for DIR in "${DIRS[@]}"; do
  SH+=("$DIR"/*.sh)
  ZSH+=("$DIR"/*.zsh)
  BSH+=("$DIR"/*.bash)
done

BSH+=(./zsh/aposteriori.bash)
ZSH+=(./zsh/aposteriori.zsh)

ACC=("$(cat -- "${SH[@]}")")
ZACC=("${ACC[@]}" "$(cat -- "${ZSH[@]}")")
BACC=("${ACC[@]}" "$(cat -- "${BSH[@]}")")

for BIN in ./zsh/*/bin/*; do
  B="${BIN##*/}"
  cp -- "$BIN" "$BINS/${B%%.*}"
done

for BIN in ./zsh/*/libexec/*; do
  B="${BIN##*/}"
  cp -- "$BIN" "$BLIB/$B"
done

for FN in ./zsh/*/fn/*.sh; do
  F="${FN%%.sh}"
  F="${F##*/}"
  ZACC+=("autoload -Uz -- \"\$ZDOTDIR/fn/$F\"")
  cp -- "$FN" "$FUNC/${F##*/}"

  PAT="$F() {"
  FF="$(<"$FN")"
  if /usr/bin/grep -F -- "$PAT" "$FN" >/dev/null; then
    BACC+=("$FF")
  else
    BACC+=("$PAT" "$FF" '}')
  fi
done

printf -- '%s\n' "${ZACC[@]}" >"$OUT/.zshrc"
printf -- '%s\n' "${BACC[@]}" >"$OUT/.bashrc"

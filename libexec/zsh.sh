#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

OS="$1"
OUT="$2"
GIT="$3"
shift -- 3

BASE="${0%/*}/.."

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
  ./zsh/{fun,dev,docker}
)

ZSH=(./zsh/apriori.zsh)
BSH=(./zsh/apriori.bash ./layers/posix/home/.zshenv)

for DIR in "${DIRS[@]}"; do
  ZSH+=("$DIR"/*.{sh,zsh})
  BSH+=("$DIR"/*.{sh,bash})
done

SH=("$GIT/dircolors.sh" "$GIT/z/z.sh" ./zsh/_*.sh)
FZF="$GIT/fzf/shell"
BSH+=(./zsh/aposteriori.{bash,sh} "${SH[@]}" "$FZF"/*.bash)
ZSH+=(./zsh/aposteriori.{zs,sh} "${SH[@]}" "$FZF"/*.zsh)

ZACC=("$(cat -- "${ZSH[@]}")")
BACC=("$(cat -- "${BSH[@]}")")

S5=("$BASE/var/bin/s5cmd" --install-completion)
ZACC+=("$(SHELL=zsh "${S5[@]}")")
BACC+=("$(SHELL=bash "${S5[@]}")")

for DIR in "${DIRS[@]}"; do
  for BIN in "$DIR/bin"/*; do
    B="${BIN##*/}"
    B="${B%%.*}"
    # shellcheck disable=SC2016
    BS='"$XDG_CONFIG_HOME/zsh/bin/"'"$B"' "$@"'

    ZACC+=("autoload -Uz -- \"\$ZDOTDIR/fn/$B\"")
    BACC+=("$B() {" "$BS" '}')
    printf -- '%s\n' "$BS" >"$FUNC/$B"
    cp -f -- "$BIN" "$BINS/$B"
  done
done

for DIR in "${DIRS[@]}"; do
  for BIN in "$DIR/libexec"/*; do
    B="${BIN##*/}"
    cp -f -- "$BIN" "$BLIB/$B"
  done
done

for DIR in "${DIRS[@]}"; do
  for FN in "$DIR/fn"/*.sh; do
    F="${FN%.sh}"
    F="${F##*/}"
    ZACC+=("autoload -Uz -- \"\$ZDOTDIR/fn/$F\"")
    cp -f -- "$FN" "$FUNC/${F##*/}"

    PAT="$F() {"
    FF="$(<"$FN")"
    if grep -F -- "$PAT" "$FN" >/dev/null; then
      BACC+=("$FF")
    else
      BACC+=("$PAT" "$FF" '}')
    fi
  done
done

printf -- '%s\n' "${ZACC[@]}" >"$OUT/.zshrc"
printf -- '%s\n' "${BACC[@]}" >"$OUT/.bashrc"

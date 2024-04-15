#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

OS="$1"
GIT="$2"
Z_OUT="$3"
B_OUT="$4"
shift -- 3

BASE="${0%/*}/.."

FUNC="$Z_OUT/fn"
BINS="$Z_OUT/bin"
BLIB="$Z_OUT/libexec"

rm -fr -- "$Z_OUT"
mkdir -p -- "$FUNC" "$BINS" "$BLIB"

DIRS=(
  ./zsh/apriori
  ./zsh/{iso,tmux}
  ./zsh/"$OS"
  ./zsh/aposteriori
  ./zsh/{fun,dev,docker}
)

ZSH=(./zsh/apriori.{sh,zsh})
BSH=(./zsh/apriori.{sh,bash} ./layers/posix/home/.zshenv)

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
ZACC+=("$(SHELL=zsh "${S5[@]}" | sed -E -e '/compinit/d')")
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
    if grep -q -F -- "$PAT" "$FN"; then
      BACC+=("$FF")
    else
      BACC+=("$PAT" "$FF" '}')
    fi
  done
done

printf -- '%s\n' "${ZACC[@]}" >"$Z_OUT/.zshrc"
printf -- '%s\n' "${BACC[@]}" >"$B_OUT/.bashrc"

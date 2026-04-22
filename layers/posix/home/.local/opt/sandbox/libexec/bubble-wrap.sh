#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS=''
LONG_OPTS='auth,network,profile:,dir:,file:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AUTH=0
NETWORK=0
USER_PROFILES=()
DIRS=()
FILES=()
while true; do
  case "$1" in
  --auth)
    AUTH=1
    shift -- 1
    ;;
  --network)
    NETWORK=1
    shift -- 1
    ;;
  --profile)
    USER_PROFILES+=("$2")
    shift -- 2
    ;;
  --dir)
    DIRS+=("$2")
    shift -- 2
    ;;
  --file)
    FILES+=("$2")
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    set -x
    exit 2
    ;;
  esac
done

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-"$XDG_CACHE_HOME"}"

RO_BIND=(
  /bin
  /etc
  /lib
  /lib64
  /opt
  /sbin
  /usr

  "$HOME/.bashrc"
  "$HOME/.netrc"
  "$HOME/.tool-versions"
  "$HOME/.zshenv"

  "$HOME/.local/bin"
  "$HOME/.local/lbin"
  "$HOME/.local/libexec"
  "$HOME/.local/lprofile.d"

  "$XDG_CONFIG_HOME/asdf"
  "$XDG_CONFIG_HOME/bat"
  "$XDG_CONFIG_HOME/bottom"
  "$XDG_CONFIG_HOME/bundle"
  "$XDG_CONFIG_HOME/cloc"
  "$XDG_CONFIG_HOME/fzf"
  "$XDG_CONFIG_HOME/gem"
  "$XDG_CONFIG_HOME/git"
  "$XDG_CONFIG_HOME/helix"
  "$XDG_CONFIG_HOME/irb"
  "$XDG_CONFIG_HOME/mpv"
  "$XDG_CONFIG_HOME/mypy"
  "$XDG_CONFIG_HOME/npm"
  "$XDG_CONFIG_HOME/nvim"
  "$XDG_CONFIG_HOME/posh"
  "$XDG_CONFIG_HOME/powershell"
  "$XDG_CONFIG_HOME/psql"
  "$XDG_CONFIG_HOME/python"
  "$XDG_CONFIG_HOME/readline"
  "$XDG_CONFIG_HOME/rediscli"
  "$XDG_CONFIG_HOME/ripgrep"
  "$XDG_CONFIG_HOME/terraform"
  "$XDG_CONFIG_HOME/tmux"
  "$XDG_CONFIG_HOME/vim"
  "$XDG_CONFIG_HOME/yazi"
  "$XDG_CONFIG_HOME/zsh"
)

RW_BIND=(
  "$HOME/.local/asdf"
  "$PWD"
  "$XDG_CACHE_HOME"
)

TMPFS=(
  "$XDG_CACHE_HOME/aerc"
  "$XDG_CACHE_HOME/isync"
  "$XDG_CACHE_HOME/maildir"
  "$XDG_CACHE_HOME/tmux"
)

if [[ -v TMPDIR && $TMPDIR != /tmp ]]; then
  RW_BIND+=("$TMPDIR")
fi

# shellcheck disable=SC2154
if ((AUTH)); then
  RO_BIND+=(
    "$HOME/.ssh"
    "$XDG_CONFIG_HOME/ssh"
    "$XDG_DATA_HOME/ssh"
  )
  RW_BIND+=(
    "$HOME/.gnupg"
    "$XDG_RUNTIME_DIR/gnupg"
  )
  if [[ -v SSH_AUTH_SOCK ]]; then
    RW_BIND+=("$SSH_AUTH_SOCK")
  fi
fi

for P in "${DIRS[@]}" "${FILES[@]}"; do
  if [[ $P == *:ro ]]; then
    RO_BIND+=("${P%:ro}")
  else
    RW_BIND+=("$P")
  fi
done

for P in "${USER_PROFILES[@]}"; do
  case "$P" in
  *)
    set -x
    exit 2
    ;;
  esac
done

BWRAP=(
  bwrap
  --unshare-all
  --die-with-parent
  --new-session

  --proc /proc
  --dev /dev
  --dev-bind /dev/tty /dev/tty

  --tmpfs /tmp
  --tmpfs "$HOME"
)

if ((NETWORK)); then
  BWRAP+=(--share-net)
fi

for P in "${RO_BIND[@]}"; do
  BWRAP+=(--ro-bind-try "$P" "$P")
done

for P in "${RW_BIND[@]}"; do
  BWRAP+=(--bind-try "$P" "$P")
done

for P in "${TMPFS[@]}"; do
  BWRAP+=(--tmpfs "$P")
done

exec -- "$@"

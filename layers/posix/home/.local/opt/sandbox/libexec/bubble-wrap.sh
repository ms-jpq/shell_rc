#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='a,n,d:,f:'
LONG_OPTS='auth,network,dir:,file:'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

AUTH=0
NETWORK=0
DIRS=()
FILES=()
while true; do
  case "$1" in
  -a | --auth)
    AUTH=1
    shift -- 1
    ;;
  -n | --network)
    NETWORK=1
    shift -- 1
    ;;
  -d | --dir)
    DIRS+=("$2")
    shift -- 2
    ;;
  -f | --file)
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

TMPFS=(
  "$HOME"
  /tmp

  "$XDG_CACHE_HOME/aerc"
  "$XDG_CACHE_HOME/isync"
  "$XDG_CACHE_HOME/maildir"
  "$XDG_CACHE_HOME/tmux"
)

RO_BIND=(
  /bin
  /etc
  /lib
  /lib64
  /opt
  /sbin
  /usr

  "$HOME/.bashrc"
  "$HOME/.gitconfig"
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
  "$XDG_CACHE_HOME"
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
    "$XDG_STATE_HOME/ssh"
  )
  if [[ -v SSH_AUTH_SOCK ]]; then
    RW_BIND+=("$SSH_AUTH_SOCK")
  fi
fi

for P in "${DIRS[@]}" "${FILES[@]}"; do
  if [[ $P == *:rw ]]; then
    RW_BIND+=("${P%:rw}")
  else
    RO_BIND+=("$P")
  fi
done
RW_BIND+=("$PWD")

if ((NETWORK)); then
  RO_BIND+=(/run/systemd/resolve/stub-resolv.conf)
fi

UNSHARE=(--unshare-ipc --unshare-net --unshare-uts --unshare-cgroup-try)
if ((UID)); then
  UNSHARE+=(--unshare-user-try)
fi

BWRAP=(
  bwrap
  --die-with-parent
  "${UNSHARE[@]}"

  --proc /proc
  --dev /dev
  --dev-bind /dev/tty /dev/tty
)

if ((NETWORK)); then
  BWRAP+=(--share-net)
fi

for P in "${TMPFS[@]}"; do
  BWRAP+=(--tmpfs "$P")
done

for P in "${RO_BIND[@]}"; do
  BWRAP+=(--ro-bind-try "$P" "$P")
done

for P in "${RW_BIND[@]}"; do
  BWRAP+=(--bind-try "$P" "$P")
done

exec -- "${BWRAP[@]}" "$@"

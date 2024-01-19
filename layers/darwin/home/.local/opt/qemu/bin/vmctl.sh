#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LONG_OPTS='fork:,vnc'
GO="$(getopt --options='' --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"
ARGV=("$@")

DIR="${0%/*}/.."
VNC=0
while (($#)); do
  case "$1" in
  -f | --fork)
    FORK="$2"
    shift -- 2
    ;;
  --vnc)
    VNC=1
    shift -- 1
    ;;
  --)
    break
    ;;
  *)
    exit 2
    ;;
  esac
done

case $# in
1)
  ACTION=''
  shift -- 1
  ;;
*)
  ACTION="${ACTION:-"$2"}"
  shift -- 2
  ;;
esac

NAME="${1:-""}"
if (($#)); then
  shift -- 1
fi

# shellcheck disable=SC2154
LIB="$XDG_DATA_HOME/qemu"
# shellcheck disable=SC2154
CACHE="$XDG_CACHE_HOME/qemu"

ROOT="$LIB/$NAME"
QMP_SOCK="$ROOT/qmp.sock"
CON_SOCK="$ROOT/con.sock"
QM_SOCK="$ROOT/qm.sock"
VNC_SOCK="$ROOT/vnc.sock"

RAW=vm.raw
DRIVE="$ROOT/$RAW"
CLOUD_INIT="$ROOT/cloud-init.iso"

SSH_LOCATION="$ROOT/ssh.conn"
SSH_CMD=(ssh -l root -p)

PASSWD='root'

ssh_pp() {
  local -- conn="$1"
  SSH_HOST="${conn%%:*}"
  SSH_PORT="${conn##*:}"
  {
    printf -- '\n%s' '>>> '
    printf -- '%q ' "${SSH_CMD[@]}" "$SSH_PORT" "$SSH_HOST"
    printf -- '<<<\n\n'
  } >&2
}

case "$ACTION" in
'')
  mkdir -v -p -- "$LIB"
  LS=(ls -AFhl --color=auto -- "$LIB")
  printf -- '%q ' "${LS[@]}" >&2
  exec -- "${LS[@]}"
  ;;
remove)
  {
    set -x
    if ! [[ -k "$ROOT" ]]; then
      mkdir -p -- "$ROOT"
      exec -- flock --nonblock "$ROOT" rm -v -rf -- "$ROOT"
    else
      exit 1
    fi
  } >&2
  ;;
pin)
  exec -- chmod -v +t "$ROOT" >&2
  ;;
unpin)
  exec -- chmod -v -t "$ROOT" >&2
  ;;
new)
  {
    if ! [[ -v UNDER ]]; then
      mkdir -v -p -- "$ROOT"
      UNDER=1 exec -- flock --nonblock "$ROOT" "$0" "${ARGV[@]}"
    fi

    if ! [[ -f "$CLOUD_INIT" ]]; then
      "$DIR/libexec/cloud-init.sh" "$NAME" "$CLOUD_INIT"
    fi

    if [[ -v FORK ]]; then
      F_DRIVE="$LIB/$FORK/$RAW"

      set -x
      if ! [[ -f "$F_DRIVE" ]]; then
        exit 1
      fi
      if [[ -f "$DRIVE" ]]; then
        exit 1
      fi

      cp -v -f -- "$F_DRIVE" "$DRIVE"
    else
      cp -v -f -- "$CACHE"/*.raw "$DRIVE"
      qemu-img resize -f raw -- "$DRIVE" +88G
    fi
  } >&2
  exit
  ;;
run)
  if ! [[ -f "$DRIVE" ]] || [[ -v FORK ]]; then
    ACTION=new "$0" "${ARGV[@]}"
  fi

  SSH_CONN="${SSH:-"127.0.0.1:$("$DIR/libexec/ssh-port.sh")"}"

  KERNEL=("$CACHE"/*-vmlinuz-*)
  INITRD=("$CACHE"/*-initrd-*)

  QARGV=(
    "$DIR/libexec/qemu-aarch64.sh"
    --qmp "$QMP_SOCK"
    --monitor "$QM_SOCK"
    --ssh "$SSH_CONN"
    --kernel "${KERNEL[@]}"
    --initrd "${INITRD[@]}"
    --drive "$DRIVE"
    --root '/dev/vda1'
    --drive "$CLOUD_INIT,readonly=on"
  )
  if ! [[ -t 0 ]]; then
    QARGV+=(--console "$CON_SOCK")
  fi
  if ((VNC)); then
    QARGV+=(
      --vnc "unix:$VNC_SOCK"
      --passwd "$PASSWD"
    )
  fi
  QARGV+=("$@")

  ssh_pp "$SSH_CONN"
  printf -- '%s' "$SSH_CONN" >"$SSH_LOCATION"
  set -x
  exec -- flock --nonblock "$ROOT" "${QARGV[@]}"
  ;;
vnc)
  open -u "vnc://:$PASSWD@localhost" >&2
  exec -- socat 'TCP-LISTEN:5900,reuseaddr,fork' "UNIX-CONNECT:$VNC_SOCK"
  ;;
console)
  SOCK="$CON_SOCK"
  ;;
ssh)
  LOCATION="$(<"$SSH_LOCATION")"
  ssh_pp "$LOCATION"
  AV=()
  if (($#)); then
    printf -v A -- '%q ' "$@"
    AV+=("$A")
  fi
  exec -- "${SSH_CMD[@]}" "$SSH_PORT" "$SSH_HOST" "${AV[@]}"
  ;;
monitor)
  SOCK="$QM_SOCK"
  ;;
qmp)
  SOCK="$QMP_SOCK"
  ;;
*)
  printf -- '%s' '>? '
  printf -- '%q ' "$0" "${ARGV[@]}"
  printf -- '\n'
  exit 2
  ;;
esac

exec -- socat "READLINE,history=$SOCK.hist" "UNIX-CONNECT:$SOCK"

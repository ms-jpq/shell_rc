#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPTS='n:,a:,f:'
LONG_OPTS='name:,fork:,vnc'
GO="$(getopt --options="$OPTS" --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

DIR="${0%/*}/.."
NAME='_'
VNC=0
while (($#)); do
  case "$1" in
  -n | --name)
    NAME="$2"
    shift -- 2
    ;;
  -f | --fork)
    FORK="$2"
    shift -- 2
    ;;
  --vnc)
    VNC=1
    shift -- 1
    ;;
  --)
    ACTION="${2:-run}"
    shift -- 2 || shift -- 1
    break
    ;;
  *)
    exit 2
    ;;
  esac
done

# shellcheck disable=SC2154
LIB="$XDG_DATA_HOME/qemu"
# shellcheck disable=SC2154
CACHE="$XDG_CACHE_HOME/qemu"
ROOT="$LIB/$NAME"

QMP_SOCK="$ROOT/qmp.sock"
CON_SOCK="$ROOT/con.sock"
QM_SOCK="$ROOT/qm.sock"
VNC_SOCK="$ROOT/vnc.sock"

FS_ROOT='/dev/vda1'

RAW=vm.raw
DRIVE="$ROOT/$RAW"
CLOUD_INIT="$ROOT/cloud-init.iso"

SSH_LOCATION="$ROOT/ssh.conn"
SSH_CMD=(ssh -l root -p)

PASSWD='root'

fwait() {
  {
    mkdir -v -p -- "$1"
    set -x
    until flock --nonblock "$1" true; do
      sleep -- 1
    done
    set +x
  } >&2
}

lsa() {
  {
    mkdir -v -p -- "$LIB"
    ls -AFhl --color=auto -- "$LIB"
  } >&2
}

new() {
  {
    fwait "$ROOT"
    if [[ -v FORK ]]; then
      F_DRIVE="$LIB/$FORK/$RAW"

      printf -- '%q%s%q\n' "$F_DRIVE" ' -> ' "$DRIVE" >&2
      if ! [[ -f "$F_DRIVE" ]]; then
        printf -- '%s%q\n' '>? ' "$F_DRIVE"
        exit 1
      fi
      if [[ -f "$DRIVE" ]]; then
        printf -- '%s%q\n' '>! ' "$DRIVE"
        lsa
        exit 1
      fi

      mkdir -v -p -- "$ROOT" >&2
      flock --nonblock "$ROOT" cp -v -f -- "$F_DRIVE" "$DRIVE"
    else
      flock --nonblock "$ROOT" cp -v -f -- "$CACHE"/*.raw "$DRIVE"
      flock --nonblock "$ROOT" qemu-img resize -f raw -- "$DRIVE" +88G
    fi
  } >&2
}

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
n | new)
  new
  exec -- true
  ;;
r | run)
  if ! [[ -f "$DRIVE" ]] || [[ -v FORK ]]; then
    new
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
    --root "$FS_ROOT"
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

  fwait "$ROOT"
  if ! [[ -f "$CLOUD_INIT" ]]; then
    "$DIR/libexec/cloud-init.sh" "$NAME" "$CLOUD_INIT"
  fi
  ssh_pp "$SSH_CONN"
  printf -- '%s' "$SSH_CONN" >"$SSH_LOCATION"
  exec -- flock "$ROOT" "${QARGV[@]}"
  ;;
l | ls)
  lsa
  exec -- true
  ;;
rm | remove)
  set -x
  if ! [[ -k "$ROOT" ]]; then
    mkdir -p -- "$ROOT" >&2
    exec -- flock --nonblock "$ROOT" rm -v -rf -- "$ROOT"
  else
    exit 1
  fi
  ;;
pin)
  exec -- chmod -v +t "$ROOT" >&2
  ;;
unpin)
  exec -- chmod -v -t "$ROOT" >&2
  ;;
v | vnc)
  open -u "vnc://:$PASSWD@localhost" >&2
  exec -- socat 'TCP-LISTEN:5900,reuseaddr,fork' "UNIX-CONNECT:$VNC_SOCK"
  ;;
c | console)
  SOCK="$CON_SOCK"
  ;;
s | ssh)
  LOCATION="$(<"$SSH_LOCATION")"
  ssh_pp "$LOCATION"
  AV=()
  if (($#)); then
    printf -v A -- '%q ' "$@"
    AV+=("$A")
  fi
  exec -- "${SSH_CMD[@]}" "$SSH_PORT" "$SSH_HOST" "${AV[@]}"
  ;;
m | monitor)
  SOCK="$QM_SOCK"
  ;;
q | qmp)
  SOCK="$QMP_SOCK"
  ;;
*)
  exit 2
  ;;
esac

exec -- socat "READLINE,history=$SOCK.hist" "UNIX-CONNECT:$SOCK"

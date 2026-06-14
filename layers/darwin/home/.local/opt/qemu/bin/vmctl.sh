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
  ACTION="${ACTION:-$2}"
  shift -- 2
  ;;
esac

NAME="${1:-}"
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
SSH_SOCK="$ROOT/ssh.sock"

RAW=vm.raw
DRIVE="$ROOT/$RAW"
CLOUD_INIT="$ROOT/cloud-init.iso"

printf -v SSH_CONN -- '%q ' nc -U -- "$SSH_SOCK"
SSH_CMD=(ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand="$SSH_CONN" -l root -- localhost)

PASSWD='root'

ssh_pp() {
  {
    printf -- '\n%s' '>>> '
    printf -- '%s' "${SSH_CMD[*]@Q}"
    printf -- '<<<\n\n'
  } >&2
}

case "$ACTION" in
'')
  mkdir -v -p -- "$LIB"
  LS=(ls -AFhl --color=auto -- "$LIB")
  printf -- '%s' "${LS[*]@Q}" >&2
  exec -- "${LS[@]}"
  ;;
remove)
  {
    set -x
    if ! [[ -k $ROOT ]]; then
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

    if ! [[ -f $CLOUD_INIT ]]; then
      "$DIR/libexec/cloud-init.sh" "$NAME" "$CLOUD_INIT"
    fi

    if [[ -v FORK ]]; then
      F_DRIVE="$LIB/$FORK/$RAW"

      set -x
      if ! [[ -f $F_DRIVE ]]; then
        exit 1
      fi
      if [[ -f $DRIVE ]]; then
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
  if ! [[ -f $DRIVE ]] || [[ -v FORK ]]; then
    ACTION=new "$0" "${ARGV[@]}"
  fi

  KERNEL=("$CACHE"/*-vmlinuz-*)
  INITRD=("$CACHE"/*-initrd-*)

  QARGV=(
    "$DIR/libexec/qemu-aarch64.sh"
    --qmp "$QMP_SOCK"
    --monitor "$QM_SOCK"
    --ssh "$SSH_SOCK"
    --kernel "${KERNEL[@]}"
    --initrd "${INITRD[@]}"
    --drive "$DRIVE"
    --root '/dev/vda1'
    --drive "$CLOUD_INIT,read-only=on"
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

  ssh_pp
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
  ssh_pp
  AV=()
  if (($#)); then
    A="${*@Q}"
    AV+=("$A")
  fi
  exec -- "${SSH_CMD[@]}" "${AV[@]}"
  ;;
monitor)
  SOCK="$QM_SOCK"
  ;;
qmp)
  SOCK="$QMP_SOCK"
  ;;
*)
  printf -- '%s' '>? '
  printf -- '%s' "${0@Q} ${ARGV[*]@Q}"
  printf -- '\n'
  exit 2
  ;;
esac

exec -- socat "READLINE,history=$SOCK.hist" "UNIX-CONNECT:$SOCK"

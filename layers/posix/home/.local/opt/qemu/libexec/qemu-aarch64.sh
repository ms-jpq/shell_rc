#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BREW="${BREW:-"$(brew --prefix)"}"

LONG_OPTS='sudo,cpu:,mem:,qmp:,console:,monitor:,vnc:,passwd:,kernel:,initrd:,drive:,root:,smbios:,ssh:'
GO="$("$BREW/opt/gnu-getopt/bin/getopt" --options='' --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

SUDO=0
DRIVES=()
OEM_STRINGS=()
while (($#)); do
  case "$1" in
  --sudo)
    SUDO=1
    shift -- 1
    ;;
  --cpu)
    CPU="$2"
    shift -- 2
    ;;
  --mem)
    MEM="$2"
    shift -- 2
    ;;
  --qmp)
    QMP="$2"
    shift -- 2
    ;;
  --console)
    CONSOLE="$2"
    shift -- 2
    ;;
  --monitor)
    MONITOR="$2"
    shift -- 2
    ;;
  --vnc)
    VNC="$2"
    shift -- 2
    ;;
  --passwd)
    PASSWD="$2"
    shift -- 2
    ;;
  --kernel)
    KERNEL="$2"
    shift -- 2
    ;;
  --initrd)
    INITRD="$2"
    shift -- 2
    ;;
  --drive)
    DRIVES+=("$2")
    shift -- 2
    ;;
  --root)
    ROOT="$2"
    shift -- 2
    ;;
  --smbios)
    OEM_STRINGS+=("$2")
    shift -- 2
    ;;
  --ssh)
    SSH="$2"
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    exit 1
    ;;
  esac
done

if ((SUDO)) && ((UID)); then
  exec -- --preserve-env -- "$0" "$@"
fi

if ! [[ -v CPU ]]; then
  NPROCS="$(sysctl -n hw.ncpu)"
  CPU="cpus=$((NPROCS / 2))"
fi

ARGV=(
  qemu-system-aarch64
  -compat 'deprecated-input=crash'
  -nodefaults
  -no-user-config
  -machine 'type=virt,acpi=off,accel=hvf'
  -cpu max
  -smp "$CPU"
  -m "${MEM:-"size=1G"}"
)

KERNEL_COMMANDS=(
  reboot=triple
  panic=-1
  random.trust_cpu=on
  random.trust_bootloader=on
  "root=$ROOT"
)

ARGV+=(
  -kernel "$KERNEL"
  -initrd "$INITRD"
  -append "${KERNEL_COMMANDS[*]}"
)

ARGV+=(
  -device virtio-rng-pci-non-transitional
  -device 'virtio-balloon-pci-non-transitional,deflate-on-oom=on,free-page-reporting=on'
)

if [[ -n "${CONSOLE:-""}" ]]; then
  ARGV+=(-serial "unix:server=on,wait=off,path=$CONSOLE")
else
  ARGV+=(-serial stdio)
fi

if [[ -n "${QMP:-""}" ]]; then
  ARGV+=(-qmp "unix:$QMP,server,nowait")
fi

if [[ -n "${MONITOR:-""}" ]]; then
  ARGV+=(-monitor "unix:$MONITOR,server,nowait")
fi

if [[ -n "${VNC:-""}" ]]; then
  ID='s0'
  ARGV+=(
    -object "secret,id=$ID,format=raw,data=$PASSWD"
    -vnc "$VNC,password-secret=$ID"
    -device "ich9-intel-hda"
    -device 'virtio-gpu-pci'
    -device 'virtio-keyboard-pci'
    -device 'virtio-tablet-pci'
  )
else
  ARGV+=(-nographic)
fi

NIC='model=virtio-net-pci-non-transitional'
if [[ -v SSH ]]; then
  SSH_FWD=",hostfwd=tcp:$SSH-:22"
else
  SSH_FWD=''
fi
ARGV+=(-nic "user,${NIC}$SSH_FWD")

if ! ((UID)); then
  ARGV+=(-nic "vmnet-shared,$NIC")
fi

for IDX in "${!DRIVES[@]}"; do
  DRIVE="${DRIVES[$IDX]}"
  ID="dri$IDX"
  ARGV+=(
    -drive "if=none,format=raw,cache=none,id=$ID,file=$DRIVE"
    -device "virtio-blk-pci-non-transitional,drive=$ID"
  )
done

if (("${#OEM_STRINGS[@]}")); then
  ACC=()
  for OEM_STRING in "${OEM_STRINGS[@]}"; do
    ACC+=("value=$OEM_STRING")
  done
  IFS=','
  ARGV+=(-smbios "type=11,${ACC[*]}")
  unset -- IFS
fi

ARGV+=("$@")

pprint() {
  while (($#)); do
    NEXT="${2:-""}"
    if [[ -n "$NEXT" ]] && ! [[ "$NEXT" =~ ^- ]]; then
      CH=' '
    else
      CH='\n'
    fi
    printf -- "%s$CH" "$1"
    shift -- 1
  done | column -t >&2
}

pprint "${ARGV[@]}"
exec -- "${ARGV[@]}"

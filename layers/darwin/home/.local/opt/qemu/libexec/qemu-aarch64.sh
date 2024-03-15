#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LONG_OPTS='sudo,cpu:,mem:,qmp:,console:,monitor:,vnc:,passwd:,kernel:,initrd:,drive:,root:,smbios:,ssh:'
GO="$(getopt --options='' --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
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
    CPUS="$2"
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
    PASSWD="$(base64 <<<"$2")"
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

if [[ -z "${CPUS:-""}" ]]; then
  NPROCS="$(sysctl -n hw.ncpu)"
  CPUS="cpus=$((NPROCS / 2))"
fi

ARGV=(
  qemu-system-aarch64
  -compat 'deprecated-input=crash'
  -nodefaults
  -no-user-config
  -machine 'type=virt,acpi=off,accel=hvf'
  -cpu max
  -smp "$CPUS"
  -m "${MEM:-"size=1G"}"
)

KERNEL_COMMANDS=(
  reboot=triple
  panic=-1
  random.trust_cpu=on
  random.trust_bootloader=on
  console=hvc0
  "root=$ROOT"
)

ARGV+=(
  -kernel "$KERNEL"
  -initrd "$INITRD"
  -append "${KERNEL_COMMANDS[*]}"
)

CON='con0'
ARGV+=(
  -device 'virtio-serial-device'
  -device "virtconsole,chardev=$CON"
)
if [[ -n "${CONSOLE:-""}" ]]; then
  ARGV+=(-chardev "socket,server=on,wait=off,id=$CON,path=$CONSOLE")
else
  ARGV+=(-chardev "stdio,id=$CON")
fi

ARGV+=(
  -device virtio-rng-pci-non-transitional
  -device 'virtio-balloon-pci-non-transitional,deflate-on-oom=on,free-page-reporting=on'
)

if [[ -n "${QMP:-""}" ]]; then
  ARGV+=(-qmp "unix:$QMP,server,nowait")
fi

if [[ -n "${MONITOR:-""}" ]]; then
  ARGV+=(-monitor "unix:$MONITOR,server,nowait")
fi

if [[ -n "${VNC:-""}" ]]; then
  ID='sec0'
  ARGV+=(
    -object "secret,id=$ID,format=base64,data=$PASSWD"
    -vnc "$VNC,password-secret=$ID"
    -device 'virtio-gpu-pci'
    -device 'virtio-keyboard-pci'
    -device 'virtio-sound-pci'
    -device 'virtio-tablet-pci'
  )
else
  ARGV+=(-nographic)
fi

if [[ -v SSH ]]; then
  SSH_FWD=",hostfwd=tcp:$SSH-:22"
else
  SSH_FWD=''
fi

IDX=0
NET="net$IDX"
NIC='virtio-net-pci-non-transitional'
ARGV+=(
  -netdev "user,id=$NET,dnssearch=${HOSTNAME}$SSH_FWD"
  -device "$NIC,netdev=$NET"
)

if ! ((UID)); then
  NET="net$((++IDX))"
  ARGV+=(
    -netdev "vmnet-shared,id=$NET"
    -device "$NIC,netdev=$NET"
  )
fi

BLKDEV_OPTIONS=(
  raw
  file.driver=file
  file.aio=threads
  cache.direct=on
)
printf -v BLKOPTS -- '%s,' "${BLKDEV_OPTIONS[@]}"

for IDX in "${!DRIVES[@]}"; do
  DRIVE="${DRIVES[$IDX]}"
  ID="blk$IDX"
  ARGV+=(
    -blockdev "${BLKOPTS}node-name=$ID,file.filename=$DRIVE"
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

"${0%/*}/../libexec/pprint.sh" "${ARGV[@]}"
exec -- "${ARGV[@]}"

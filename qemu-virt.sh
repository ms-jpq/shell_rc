#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LONG_OPTS='cpu:,mem:,gui,img:'
GO="$(getopt --options='' --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval set -- "$GO"

GUI=0
while (($#)); do
  case "$1" in
  --cpu)
    CPU="$2"
    shift -- 2
    ;;
  --mem)
    MEM="$2"
    shift -- 2
    ;;
  --gui)
    GUI=1
    shift -- 1
    ;;
  --img)
    IMG="$2"
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

ARGV=(
  qemu-system-aarch64
  -nodefaults
  -no-user-config
  -machine 'type=virt,accel=hvf'
  -cpu max
  -smp "${CPU:-"cpus=$(nproc)"}"
  -m "${MEM:-"size=1G"}"
)

CONSOLE_ID="virtiocon-$(uuidgen)"
ARGV+=(
  -device virtio-serial-pci-non-transitional
  -chardev "stdio,id=$CONSOLE_ID"
  -device "virtconsole,chardev=$CONSOLE_ID"
)

if ((GUI)); then
  ARGV+=(
    -device 'virtio-gpu-pci'
    -device 'virtio-tablet-pci'
    -device 'virtio-keyboard-pci'
  )
else
  ARGV+=(
    -nographic
  )
fi

NIC_ID="tap-$(uuidgen)"
ARGV+=(
  -netdev "user,id=$NIC_ID"
  -device "virtio-net-pci-non-transitional,netdev=$NIC_ID"
)

ARGV+=(-bios "$(brew --prefix)/opt/qemu/share/qemu/edk2-aarch64-code.fd")

DRIVE_ID="drive-$(uuidgen)"
ARGV+=(
  -drive "if=none,aio=threads,file=$IMG,id=$DRIVE_ID"
  -device "virtio-blk-pci-non-transitional,drive=$DRIVE_ID"
)

ARGV+=("$@")

pprint() {
  while (($#)); do
    if ! [[ "${2:-""}" =~ ^- ]]; then
      break
    else
      printf -- '%s\n' "$1"
      shift -- 1
    fi
  done

  for ARG in "$@"; do
    case "$ARG" in
    -*)
      printf -- '%s ' "$ARG"
      ;;
    *)
      printf -- '%s\n' "$ARG"
      ;;
    esac
  done
}

pprint "${ARGV[@]}" | column -t >&2

exec -- "${ARGV[@]}"

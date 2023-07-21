#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LONG_OPTS='cpu:,mem:,monitor:,gui,drive:,smbios:'
GO="$(getopt --options='' --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

DRIVES=()
OEM_STRINGS=()
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
  --monitor)
    MONITOR="$2"
    shift -- 2
    ;;
  --gui)
    GUI=1
    shift -- 1
    ;;
  --drive)
    DRIVES+=("$2")
    shift -- 2
    ;;
  --smbios)
    OEM_STRINGS+=("$2")
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

if [[ -v GUI ]]; then
  ARGV+=(
    -device 'virtio-gpu-pci'
    -device 'virtio-tablet-pci'
    -device 'virtio-keyboard-pci'
  )
else
  ARGV+=(
    -nographic
    -serial stdio
  )
fi

if [[ -v MONITOR ]]; then
  ARGV+=(-monitor "$MONITOR,server,nowait")
fi

ARGV+=(-nic "user,model=virtio-net-pci-non-transitional")

ARGV+=(-bios "$(brew --prefix)/opt/qemu/share/qemu/edk2-aarch64-code.fd")

for DRIVE in "${DRIVES[@]}"; do
  ARGV+=(-drive "if=virtio,discard=unmap,aio=threads,file=$DRIVE")
done

for OEM_STRING in "${OEM_STRINGS[@]}"; do
  ARGV+=(-smbios "type=11,path=$OEM_STRING")
done

ARGV+=("$@")

pprint() {
  while (($#)); do
    NEXT="${2:-""}"
    if [[ -n "$NEXT" ]] && ! [[ "$NEXT" =~ ^- ]]; then
      printf -- '%s ' "$1"
    else
      printf -- '%s\n' "$1"
    fi

    shift -- 1
  done | column -t >&2
}

pprint "${ARGV[@]}"
exec -- "${ARGV[@]}"

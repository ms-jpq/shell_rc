#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LONG_OPTS='cpu:,mem:,mon:,img:,smbios:,cloudinit:'
GO="$(getopt --options='' --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval set -- "$GO"

MON=
SMBIOS_OEM=
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
  --mon)
    MON="$2"
    shift -- 2
    ;;
  --img)
    IMG="$2"
    shift -- 2
    ;;
  --smbios)
    SMBIOS_OEM="$2"
    shift -- 2
    ;;
  --cloudinit)
    CLOUDINIT="$2"
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

ARGV+=(
  -nographic
  -serial stdio
)

if [[ -n "$MON" ]]; then
  ARGV+=(-monitor "$MON,server,nowait")
fi

ARGV+=(-nic "user,model=virtio-net-pci-non-transitional")

ARGV+=(-bios "$(brew --prefix)/opt/qemu/share/qemu/edk2-aarch64-code.fd")

ARGV+=(-drive "if=virtio,,aio=threads,file=$IMG")

if [[ -n "$SMBIOS_OEM" ]]; then
  ARGV+=(-smbios "type=11,path=$SMBIOS_OEM")
fi

if [[ -n "$CLOUDINIT" ]]; then
  CLOUDISO="./tmp/cidata.iso"
  GENISO=(
    mkisofs
    -volid CIDATA
    -joliet -rock
    -output "$CLOUDISO"
    "$CLOUDINIT"
  )
  rm -fr -- "$CLOUDISO"
  ARGV+=(-drive "format=raw,file=$CLOUDISO")
else
  GENISO=(true)
fi

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

pprint "${GENISO[@]}"
pprint "${ARGV[@]}"

"${GENISO[@]}"
exec -- "${ARGV[@]}"

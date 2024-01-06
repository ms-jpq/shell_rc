.PHONY: qemu-img virtio-win

QEMU_CACHE := $(CACHE)/qemu
$(QEMU_CACHE): | $(CACHE)
	mkdir -v -p -- '$@'

QEMU_VERSION_ID := $(shell ./libexec/which-lts.sh)
CLOUD_AT := https://cloud-images.ubuntu.com/releases/$(QEMU_VERSION_ID)/release
CLOUD := $(CLOUD_AT)/ubuntu-$(QEMU_VERSION_ID)-server-cloudimg-$(GOARCH).img
KERNEL := $(CLOUD_AT)/unpacked/ubuntu-$(QEMU_VERSION_ID)-server-cloudimg-$(GOARCH)-vmlinuz-generic
INITRD := $(CLOUD_AT)/unpacked/ubuntu-$(QEMU_VERSION_ID)-server-cloudimg-$(GOARCH)-initrd-generic
CLOUD_IMG := $(QEMU_CACHE)/$(notdir $(CLOUD))

qemu-img: $(CLOUD_IMG)
$(CLOUD_IMG): | $(QEMU_CACHE)
	$(CURL) --output '$@' -- '$(CLOUD)'

qemu-img: $(QEMU_CACHE)/$(notdir $(KERNEL))
$(QEMU_CACHE)/$(notdir $(KERNEL)): | $(QEMU_CACHE)
	$(CURL) --output '$@' -- '$(KERNEL)'

qemu-img: $(QEMU_CACHE)/$(notdir $(INITRD))
$(QEMU_CACHE)/$(notdir $(INITRD)): | $(QEMU_CACHE)
	$(CURL) --output '$@' -- '$(INITRD)'

qemu-img: $(basename $(CLOUD_IMG)).raw
$(basename $(CLOUD_IMG)).raw: $(CLOUD_IMG)
	qemu-img convert -f qcow2 -O raw -- '$<' '$@'

VIRTIO_WIN_IMG := https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

virtio-win: $(QEMU_CACHE)/$(notdir $(VIRTIO_WIN_IMG))
$(QEMU_CACHE)/$(notdir $(VIRTIO_WIN_IMG)): | $(QEMU_CACHE)
	$(CURL) --output '$@' -- '$(VIRTIO_WIN_IMG)'

.PHONY: layers tar
all: tar

DIRS := root home
RSYNC := rsync --recursive --links --perms

define FS_TEMPLATE

$(TMP)/$(1)/$(2): $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/$(2)/.*')
	set -x
	LAYERS=(./layers/{posix,$(1)}/$(2))
	mkdir -p -- '$$@'
	for layer in "$$$${LAYERS[@]}"; do
		if [[ -d ""$$$$layer"" ]]; then
			$$(RSYNC) "$$$$layer/" '$$@/'
		fi
	done

layers: $(TMP)/$(1)/$(2)

endef

$(foreach dir,$(DIRS),$(foreach os,$(GOOS),$(eval $(call FS_TEMPLATE,$(os),$(dir)))))


define TAR_TEMPLATE

$(TMP)/$(1).$(2).tar: $(TMP)/$(1)/$(2)
	for layer in $$^; do
		tar -r -C "$$$$layer" -f '$$@' .
	done

tar: $(TMP)/$(1).$(2).tar

endef

$(foreach dir,$(DIRS),$(foreach os,$(GOOS),$(eval $(call TAR_TEMPLATE,$(os),$(dir)))))

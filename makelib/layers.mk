.PHONY: layers tar
all: tar

KINDS = link fs
DIRS := root home
RSYNC := rsync --mkpath --recursive --links --perms

define FS_TEMPLATE

$(1)_$(2)_$(3) := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/$(2)/$(3)/.*')

$$(TMP)/$(1)/$(3).$(2): $$($(1)_$(2)_$(3))
	LAYERS=(./layers/{posix,$(1)}/$(2)/$(3))
	mkdir -p -- '$$@'
	for layer in "$$$${LAYERS[@]}"; do
		if [[ -d ""$$$$layer"" ]]; then
			$$(RSYNC) "$$$$layer/" '$$@/'
		fi
	done

layers: $$(TMP)/$(1)/$(3).$(2)

endef

$(foreach kind,$(KINDS),$(foreach dir,$(DIRS),$(foreach os,$(OS),$(eval $(call FS_TEMPLATE,$(os),$(kind),$(dir))))))


define TAR_TEMPLATE

$$(TMP)/$(1).$(2).tar: $$(TMP)/$(1)/$(2).link $$(TMP)/$(1)/$(2).fs
	for layer in $$^; do
		tar -r -C "$$$$layer" -f '$$@' .
	done

tar: $$(TMP)/$(1).$(2).tar

endef

$(foreach dir,$(DIRS),$(foreach os,$(OS),$(eval $(call TAR_TEMPLATE,$(os),$(dir)))))

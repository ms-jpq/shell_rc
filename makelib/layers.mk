.PHONY: tar

DIRS := root home
RSYNC := rsync --mkpath --recursive --links --perms --times

define FS_TEMPLATE

$(1)_FS_$(2) := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/fs/$(2)/.*')
$(1)_LINK_$(2) := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/link/$(2)/.*')

$$(TMP)/$(1)/$(2).link: $$($(1)_LINK_$(2))
	LAYERS=(./layers/{posix,$(1)}/link/$(2))
	for layer in "$$$${LAYERS[@]}"; do
		if [[ -d ""$$$$layer"" ]]; then
			$$(RSYNC) "$$$$layer" '$$@/'
		fi
	done

$$(TMP)/$(1)/$(2).link.tar: $$(TMP)/$(1)/$(2).link
	mkdir -p -- '$$<'
	tar -c -C '$$<' -f '$$@' .

tar: $$(TMP)/$(1)/$(2).link.tar

endef

$(foreach dir,$(DIRS),$(foreach os,$(OS),$(eval $(call FS_TEMPLATE,$(os),$(dir)))))

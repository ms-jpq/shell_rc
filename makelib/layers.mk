.PHONY: tar

KINDS = link fs
DIRS := root home
RSYNC := rsync --mkpath --recursive --links --perms --times

define FS_TEMPLATE

$(1)_$(2)_$(3) := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/$(2)/$(3)/.*')

$$(TMP)/$(1)/$(3).$(2): $$($(1)_$(2)_$(3))
	LAYERS=(./layers/{posix,$(1)}/$(2)/$(3))
	for layer in "$$$${LAYERS[@]}"; do
		if [[ -d ""$$$$layer"" ]]; then
			$$(RSYNC) "$$$$layer" '$$@/'
		fi
	done

$$(TMP)/$(1)/$(3).$(2).tar: $$(TMP)/$(1)/$(3).$(2)
	mkdir -p -- '$$<'
	tar -c -C '$$<' -f '$$@' .

tar: $$(TMP)/$(1)/$(3).$(2).tar

endef

$(foreach kind,$(KINDS),$(foreach dir,$(DIRS),$(foreach os,$(OS),$(eval $(call FS_TEMPLATE,$(os),$(kind),$(dir))))))


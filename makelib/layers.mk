.PHONY: tar

RSYNC := rsync --mkpath --recursive --links --perms --times

define FS_TEMPLATE

$(1)_FS_REL := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/fs/~/.*')
$(1)_FS_ABS := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/fs/root/.*')

$(1)_LINK_REL := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/link/~/.*')
$(1)_LINK_ABS := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/link/root/.*')

$$(TMP)/$(1)/home.fs: $$($(1)_FS_REL)
	$$(RSYNC) -- './layers/posix/fs/~/' './layers/$(1)/fs/~/' '$$@'

tar: $$(TMP)/$(1)/home.fs

endef

$(foreach os,$(OS),$(eval $(call FS_TEMPLATE,$(os))))


echo:
	@echo '$(darwin_FS_REL)'

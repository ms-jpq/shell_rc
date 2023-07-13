.PHONY: tar

define FS_TEMPLATE

$(1)_FS_REL := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/fs/~/.*')
$(1)_FS_ABS := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/fs/root/.*')

$(1)_LINK_REL := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/link/~/.*')
$(1)_LINK_ABS := $$(shell find ./layers -regex './layers/\(posix\|$(1)\)/link/root/.*')

$$(TMP)/$(1)/home.link: $$($(1)_LINK_REL)
	rsync -- './layers/posix/fs/~' './layers/$(1)/fs/~' '$$@'
	rsync --mkpath --recursive --links --perms --times -- '$$@/'

tar: $$(TMP)/$(1)/home.link

endef

$(foreach os,$(OS),$(eval $(call FS_TEMPLATE,$(os))))


echo:
	@echo '$(darwin_FS_REL)'

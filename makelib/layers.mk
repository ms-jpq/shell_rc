.PHONY: layers tar
all: layers

DIRS := root home
RSYNC ?= rsync
RSY := $(RSYNC) --recursive --links --perms --keep-dirlinks

define FS_TEMPLATE

$(TMP)/$1/$2: $(shell shopt -u failglob; printf -- '%s ' ./layers/{posix,$1}/$2/**/*)
	LAYERS=(./layers/{posix,$1}/$2)
	mkdir -v -p -- '$$@'
	for layer in "$$$${LAYERS[@]}"; do
		if [[ -d ""$$$$layer"" ]]; then
			$(RSY) "$$$$layer/" '$$@/'
		fi
	done

layers: $(TMP)/$1/$2

endef

$(foreach dir,$(DIRS),$(foreach os,$(GOOS),$(eval $(call FS_TEMPLATE,$(os),$(dir)))))


define TAR_TEMPLATE

$(TMP)/$1.$2.tar: $(TMP)/$1/$2
	for layer in $$^; do
		tar -r -C "$$$$layer" -f '$$@' .
	done

tar: $(TMP)/$1.$2.tar

endef

$(foreach dir,$(DIRS),$(foreach os,$(GOOS),$(eval $(call TAR_TEMPLATE,$(os),$(dir)))))

.PHONY: layers tar
all: layers

DIRS := root home
REQS :=

REQS += ./layers/posix/home/.config/kitty/conf.d/colours.conf
./layers/posix/home/.config/kitty/conf.d/colours.conf: ./libexec/kitty.sh ./layers/posix/home/.config/kitty/map.json ./layers/posix/home/.config/ttyd/theme.json
	'$<' >'$@'

define FS_TEMPLATE

$(TMP)/$1/$2: ./libexec/lsync.sh $(shell shopt -u failglob && printf -- '%s ' ./layers/{posix,$1}/$2/**/*) $(REQS)
	'$$<' '$$@' ./layers/{posix,$1}/$2/
ifeq ($2,home)
	chmod -v g-rwx,o-rwx '$$@/.config/gnupg' '$$@/.ssh'
endif

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

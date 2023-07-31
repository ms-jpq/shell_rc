define GIT_DARWIN_REPOS

$(OPT)/qemu https://github.com/ms-jpq/mol

endef

GIT_DARWIN_REPOS := $(shell tr -s ' ' '#' <<<'$(GIT_DARWIN_REPOS)')

$(call META_2D,GIT_DARWIN_REPOS,GIT_TEMPLATE)

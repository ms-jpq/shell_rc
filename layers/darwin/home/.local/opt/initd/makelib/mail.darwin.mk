mail: $(CONFIG)/aerc/binds.conf
$(BREW_PREFIX)/opt/aerc/share/aerc/binds.conf: | pkg.posix
$(CONFIG)/aerc/binds.conf: $(CONFIG)/aerc/binds.sed | $(BREW_PREFIX)/opt/aerc/share/aerc/binds.conf
	sed -E -f '$^' -- '$|' > '$@'

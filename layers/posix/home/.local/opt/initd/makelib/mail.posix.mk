.PHONY: mail

mail: $(CONFIG)/isyncrc
$(CONFIG)/isyncrc: | $(CONFIG)/isyncrc.example
	cp -v -f -- '$|' '$@'

mail: $(CONFIG)/aerc/binds.conf
$(CONFIG)/aerc/binds.conf: $(CONFIG)/aerc/binds.sed | /opt/homebrew/opt/aerc/share/aerc/binds.conf
	sed -E -f '$^' -- '$|' > '$@'

.PHONY: mail

mail: $(CONFIG)/isyncrc
$(CONFIG)/isyncrc: | $(CONFIG)/isyncrc.example
	cp -v -f -- '$<' '$@'

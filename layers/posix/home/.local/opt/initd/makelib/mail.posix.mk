.PHONY: mail

mail: $(CONFIG)/isyncrc
$(CONFIG)/isyncrc:
	touch -- '$@'

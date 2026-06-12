.PHONY: ranger clobber.ranger

clobber: clobber.ranger
all: ranger

RANGER    := ./layers/posix/home/.config/ranger
RANGER_RC := https://raw.githubusercontent.com/ranger/ranger/refs/heads/master/ranger/config/rc.conf

clobber.ranger:
	rm -vfr -- $(RANGER)/reference.conf $(RANGER)/unmap.conf $(RANGER)/rc.conf

$(RANGER)/reference.conf:
	$(CURL) --output '$@' -- '$(RANGER_RC)'

$(RANGER)/unmap.conf: $(RANGER)/unmap.sed $(RANGER)/reference.conf
	'$<' -- '$(lastword $^)' > '$@'

ranger: $(RANGER)/rc.conf
$(RANGER)/rc.conf: $(RANGER)/rc2.conf $(RANGER)/unmap.conf $(RANGER)/keymap.conf
	cat -- '$(RANGER)/rc2.conf' '$(RANGER)/unmap.conf' '$(RANGER)/keymap.conf' > '$@'

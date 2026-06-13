.PHONY: ranger clobber.ranger

clobber: clobber.ranger
all: ranger

RANGER := ./layers/posix/home/.config/ranger

clobber.ranger:
	rm -vfr -- $(RANGER)/reference.conf $(RANGER)/unmap.conf $(RANGER)/rc.conf $(VAR)/ranger

$(VAR)/ranger: | $(VAR)
	./libexec/git-sync.sh https://github.com/ranger/ranger '$@'

$(RANGER)/reference.conf: | $(VAR)/ranger
	cp -- '$|/ranger/config/rc.conf' '$@'

$(RANGER)/unmap.conf: $(RANGER)/unmap.sed $(RANGER)/reference.conf
	'$<' -- '$(lastword $^)' > '$@'

ranger: $(RANGER)/rc.conf
$(RANGER)/rc.conf: $(RANGER)/rc2.conf $(RANGER)/unmap.conf $(RANGER)/keymap.conf
	cat -- '$(RANGER)/rc2.conf' '$(RANGER)/unmap.conf' '$(RANGER)/keymap.conf' > '$@'

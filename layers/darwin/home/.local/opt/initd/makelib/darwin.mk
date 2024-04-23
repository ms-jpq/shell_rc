.PHONY: sudo
all: sudo

sudo: /etc/pam.d/sudo_local
/etc/pam.d/sudo_local: | ./sudo_local
	sudo -- cp -v -f -- '$|' '$@'

sudo: /etc/resolver
/etc/resolver:
	sudo -- mkdir -p -- '$@'

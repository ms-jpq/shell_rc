all: /etc/update-motd.d/.noop

/etc/update-motd.d/.noop:
	shopt -u failglob
	sudo -- rm -v -fr -- '$(@D)'/*
	sudo -- touch -- '$@'

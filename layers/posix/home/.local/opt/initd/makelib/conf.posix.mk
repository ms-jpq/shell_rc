.PHONY: conf conf.posix conf.posix.ssh conf.posix.git

conf: conf.posix
conf.posix: $(CONFIG)/git/config conf.posix.ssh

$(CONFIG)/git/config: | /usr/bin/git
	touch -- '$@'
	'$|' config --global include.path user_config

conf.posix.ssh:
	./libexec/line-in-file.sh '$(HOME)/.ssh/config' 'Include ~/.config/ssh/*.conf'

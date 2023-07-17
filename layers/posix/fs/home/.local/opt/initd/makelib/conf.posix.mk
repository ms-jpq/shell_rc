.PHONY: conf conf.posix conf.posix.ssh conf.posix.git

conf: conf.posix
conf.posix: conf.posix.git conf.posix.ssh

conf.posix.git: /usr/bin/git
	'$<' config --global include.path user_config

conf.posix.ssh:
	./libexec/line-in-file.sh '$(HOME)/.ssh/config' 'Include ~/.config/ssh/*.conf'

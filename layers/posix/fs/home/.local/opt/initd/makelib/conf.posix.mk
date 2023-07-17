.PHONY: conf conf.posix conf.posix.ssh conf.posix.git

conf: conf.posix
conf.posix: conf.posix.ssh conf.posix.git

conf.posix.ssh:
	./libexec/line-in-file.sh '$(HOME)/.ssh/config' 'Include ~/.config/ssh/*.conf'

conf.posix.git:
	./libexec/line-in-file.sh '$(CONFIG)/git/config' '[include]' '[include]'$$'\n  path = user_config'

.PHONY: ssh
all: ssh

ssh: $(HP)/.ssh/authorized_keys
$(HP)/.ssh/authorized_keys:
	URI='https://github.com/ms-jpq.keys'
	$(CURL) --output '$@' -- "$$URI"

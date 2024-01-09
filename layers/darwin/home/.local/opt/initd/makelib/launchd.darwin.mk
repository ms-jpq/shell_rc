.PHONY: launchd

LAUNCH_AGENTS := $(HP)/Library/LaunchAgents

all: launchd
launchd: $(LAUNCH_AGENTS)/org.gnupg.gpg-agent.plist

$(LAUNCH_AGENTS)/org.gnupg.gpg-agent.plist: $(LAUNCH_AGENTS)/org.gnupg.gpg-agent.xml
	env -i HOME='$(HP)' ./libexec/envsubst.pl <'$<' >'$@'

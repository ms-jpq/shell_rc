$(SHARE)/tmux $(OPT)/pipx: | /usr/share/doc/python3-venv

# pkg.posix: /etc/apt/sources.list.d/ubuntu_partner.list
/etc/apt/sources.list.d/ubuntu_partner.list:
	sudo -- tee -- '$@' <<-'EOF'
	deb http://archive.canonical.com/ubuntu $(VERSION_CODENAME) partner
	EOF

/etc/apt/trusted.gpg.d/ms-jpq.gpg:
	$(CURL) -- 'https://raw.githubusercontent.com/ms-jpq/deb/refs/heads/deb/pubkey.asc' | sudo -- gpg --batch --dearmor --yes --output '$@'

pkg.posix: /etc/apt/sources.list.d/ms-jpq.list
/etc/apt/sources.list.d/ms-jpq.list: | /etc/apt/trusted.gpg.d/ms-jpq.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb https://raw.githubusercontent.com/ms-jpq/deb/refs/heads/deb/ /
	EOF

/etc/apt/trusted.gpg.d/gcp.gpg:
	$(CURL) -- 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo -- gpg --batch --dearmor --yes --output '$@'

pkg.posix: /etc/apt/sources.list.d/gcp.list
/etc/apt/sources.list.d/gcp.list: /etc/apt/trusted.gpg.d/gcp.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb https://packages.cloud.google.com/apt cloud-sdk main
	deb https://packages.cloud.google.com/apt google-cloud-ops-agent-$(VERSION_CODENAME)-all main
	EOF

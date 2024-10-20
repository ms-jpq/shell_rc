$(SHARE)/tmux $(NVIM_MVP) $(OPT)/pipx: | /usr/share/doc/python3-venv

# pkg.posix: /etc/apt/sources.list.d/ubuntu_partner.list
/etc/apt/sources.list.d/ubuntu_partner.list:
	sudo -- tee -- '$@' <<-'EOF'
	deb http://archive.canonical.com/ubuntu $(VERSION_CODENAME) partner
	EOF

/etc/apt/trusted.gpg.d/ms-jpq.gpg:
	$(CURL) -- 'https://ms-jpq.github.io/deb/pubkey.asc' | sudo -- gpg --batch --dearmor --yes --output '$@'

pkg.posix: /etc/apt/sources.list.d/ms-jpq.list
/etc/apt/sources.list.d/ms-jpq.list: | /etc/apt/trusted.gpg.d/ms-jpq.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb https://ms-jpq.github.io/deb /
	EOF

pkg.posix: /etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list
/etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list:
	sudo -- ./libexec/add-ppa.sh neovim-ppa/unstable

/etc/apt/trusted.gpg.d/charm.gpg:
	$(CURL) -- 'https://repo.charm.sh/apt/gpg.key' | sudo -- gpg --batch --dearmor --yes --output '$@'

pkg.posix: /etc/apt/sources.list.d/charm.list
/etc/apt/sources.list.d/charm.list: /etc/apt/trusted.gpg.d/charm.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb https://repo.charm.sh/apt/ * *
	EOF

/etc/apt/trusted.gpg.d/gcp.gpg:
	$(CURL) -- 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo -- gpg --batch --dearmor --yes --output '$@'

pkg.posix: /etc/apt/sources.list.d/gcp.list
/etc/apt/sources.list.d/gcp.list: /etc/apt/trusted.gpg.d/gcp.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb https://packages.cloud.google.com/apt cloud-sdk main
	EOF

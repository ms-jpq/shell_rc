APT_INSTALL := DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --yes

$(SHARE)/tmux $(NVIM_MVP) $(OPT)/pipx: | /usr/share/doc/python3-venv

/etc/apt/sources.list.d/ubuntu_partner.list:
	sudo -- tee -- '$@' <<-EOF
	deb http://archive.canonical.com/ubuntu $(VERSION_CODENAME) partner
	EOF

/etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list:
	sudo -- ./libexec/add-ppa.sh neovim-ppa/unstable

/etc/apt/trusted.gpg.d/charm.gpg:
	$(CURL) -- 'https://repo.charm.sh/apt/gpg.key' | sudo -- gpg --batch --dearmor --yes --output '$@'

/etc/apt/sources.list.d/charm.list: /etc/apt/trusted.gpg.d/charm.gpg
	sudo -- tee -- '$@' <<-EOF
	deb https://repo.charm.sh/apt/ * *
	EOF

pkg.posix: /etc/apt/sources.list.d/charm.list
pkg.posix: /etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list
pkg.posix: /etc/apt/sources.list.d/ubuntu_partner.list

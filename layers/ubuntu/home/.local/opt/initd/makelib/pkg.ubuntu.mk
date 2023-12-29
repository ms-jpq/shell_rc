APT_INSTALL := DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --yes

$(SHARE)/tmux $(NVIM_MVP) $(OPT)/pipx: | /usr/share/doc/python3-venv

pkg.posix: /etc/apt/sources.list.d/ubuntu_partner.list
/etc/apt/sources.list.d/ubuntu_partner.list:
	sudo -- tee -- '$@' <<-'EOF'
	deb http://archive.canonical.com/ubuntu $(VERSION_CODENAME) partner
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

CUDA := http://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(subst .,,$(VERSION_ID))/$(HOSTTYPE)/

/etc/apt/trusted.gpg.d/cuda.gpg:
	sudo -- $(CURL) --output '$@' -- '$(CUDA)/cuda-archive-keyring.gpg'

pkg.posix: /etc/apt/sources.list.d/cuda.list
/etc/apt/sources.list.d/cuda.list: /etc/apt/trusted.gpg.d/cuda.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb $(CUDA) /
	EOF

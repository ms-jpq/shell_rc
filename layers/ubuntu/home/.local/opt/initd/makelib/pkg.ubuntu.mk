APT_INSTALL := DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --no-install-recommends --yes
APT_DEPS := /etc/ssl/certs/ca-certificates.crt /usr/bin/curl /usr/bin/gpg /usr/bin/jq /usr/bin/git /usr/share/doc/python3-venv

/usr/bin/unzip:
	APT=(ca-certificates curl gnupg jq git unzip python3-venv)
	sudo -- apt-get update
	$(APT_INSTALL) -- "$${APT[@]}"

$(APT_DEPS): | /usr/bin/unzip

$(SHARE)/tmux $(NVIM_MVP) $(OPT)/pipx: | /usr/share/doc/python3-venv

/etc/apt/sources.list.d/ubuntu_partner.list:
	source -- /etc/os-release
	sudo -- tee -- '$@' <<-EOF
	deb http://archive.canonical.com/ubuntu $$VERSION_CODENAME partner
	EOF

/etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list: $(APT_DEPS)
	sudo -- ./libexec/add-ppa.sh neovim-ppa/unstable

/etc/apt/trusted.gpg.d/charm.gpg: $(APT_DEPS)
	$(CURL) -- 'https://repo.charm.sh/apt/gpg.key' | sudo -- gpg --batch --dearmor --yes --output '$@'

/etc/apt/sources.list.d/charm.list: /etc/apt/trusted.gpg.d/charm.gpg
	sudo -- tee -- '$@' <<-EOF
	deb https://repo.charm.sh/apt/ * *
	EOF

pkg.posix: /etc/apt/sources.list.d/charm.list
pkg.posix: /etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list
pkg.posix: /etc/apt/sources.list.d/ubuntu_partner.list

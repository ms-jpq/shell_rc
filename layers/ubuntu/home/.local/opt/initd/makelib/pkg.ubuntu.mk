APT_INSTALL := DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --no-install-recommends --yes
APT_DEPS := /etc/ssl/certs/ca-certificates.crt /usr/bin/curl /usr/bin/gpg /usr/bin/jq /usr/bin/git /usr/share/doc/python3-venv

/usr/bin/unzip:
	APT=(ca-certificates curl gnupg jq git unzip python3-venv)
	sudo -- apt-get update
	$(APT_INSTALL) -- "$${APT[@]}"
	touch -- '$@'

$(APT_DEPS): /usr/bin/unzip

$(SHARE)/tmux: /usr/share/doc/python3-venv

pkg.posix: /etc/apt/sources.list.d/ubuntu_partner.list /etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list

/etc/apt/sources.list.d/ubuntu_partner.list:
	source -- /etc/os-release
	sudo -- tee -- '$@' <<-EOF
	deb http://archive.canonical.com/ubuntu $$VERSION_CODENAME partner
	EOF

/etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list: $(APT_DEPS)
	sudo -- ./libexec/add-ppa.sh neovim-ppa/unstable

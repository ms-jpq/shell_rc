.PHONY: apt-deps
	
APT_INSTALL := DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --no-install-recommends --yes
APT_DEPS := /etc/ssl/certs/ca-certificates.crt /usr/bin/curl /usr/bin/gpg /usr/bin/jq /usr/bin/git /usr/bin/unzip

apt-deps:
	APT=(ca-certificates curl gnupg jq git unzip)
	sudo -- apt-get update
	$(APT_INSTALL) -- "$${APT[@]}"

$(APT_DEPS): apt-deps
git-deps: $(APT_DEPS)

pkg.posix: /etc/apt/sources.list.d/ubuntu_partner.list /etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list

/etc/apt/sources.list.d/ubuntu_partner.list:
	source -- /etc/os-release
	tee -- '$@' <<-EOF
	deb http://archive.canonical.com/ubuntu $$VERSION_CODENAME partner
	EOF

/etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list: $(APT_DEPS)
	sudo -- ./libexec/add-ppa.sh neovim-ppa/unstable
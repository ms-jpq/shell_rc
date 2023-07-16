.PHONY: apt apt-deps

APT_DEPS := /etc/ssl/certs/ca-certificates.crt /usr/bin/curl /usr/bin/gpg /usr/bin/jq

apt-deps:
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes -- ca-certificates curl gnupg jq

APT_DEPS: apt-deps
apt: APT_DEPS

/etc/apt/sources.list.d/ubuntu_partner.list:
	source -- /etc/os-release
	tee -- '$$@' <<-EOF
	deb http://ports.ubuntu.com/ubuntu $$VERSION_CODENAME partner
	EOF

/etc/apt/sources.list.d/ppa_neovim-ppa_unstable.list:
	./libexec/add-ppa.sh neovim-ppa/unstable

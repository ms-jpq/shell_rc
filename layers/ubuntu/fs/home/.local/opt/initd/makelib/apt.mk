.PHONY: apt-repo

apt-repo: /etc/apt/sources.list.d/ubuntu_partner.list

/etc/apt/sources.list.d/ubuntu_partner.list:
	source -- /etc/os-release
	tee -- '$$@' <<-EOF
	deb http://ports.ubuntu.com/ubuntu $$VERSION_CODENAME partner
	EOF

/etc/apt/sources.list.d/neovim-ppa.list:
	source -- /etc/os-release
	tee -- '$$@' <<-EOF
	deb http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu $$VERSION_CODENAME main
	EOF

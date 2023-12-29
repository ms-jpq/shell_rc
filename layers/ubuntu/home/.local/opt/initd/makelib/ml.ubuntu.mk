/etc/apt/trusted.gpg.d/docker.gpg:
	$(CURL) -- 'https://download.docker.com/linux/ubuntu/gpg' | sudo -- gpg --batch --dearmor --yes --output '$@'

pkg.posix: /etc/apt/sources.list.d/docker.list
/etc/apt/sources.list.d/docker.list: /etc/apt/trusted.gpg.d/docker.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb https://download.docker.com/linux/ubuntu $(VERSION_CODENAME) stable
	EOF

pkg.posix: /etc/docker/daemon.json
/etc/docker/daemon.json: | /etc/docker/daemon2.json
	sudo -- cp -v -- '$|' '$@'

CUDA := http://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(subst .,,$(VERSION_ID))/$(HOSTTYPE)/

/etc/apt/trusted.gpg.d/cuda.gpg:
	sudo -- $(CURL) --output '$@' -- '$(CUDA)/cuda-archive-keyring.gpg'

pkg.posix: /etc/apt/sources.list.d/cuda.list
/etc/apt/sources.list.d/cuda.list: /etc/apt/trusted.gpg.d/cuda.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb $(CUDA) /
	EOF

/etc/apt/trusted.gpg.d/nvidia-container-toolkit.gpg:
	$(CURL) -- 'https://nvidia.github.io/libnvidia-container/gpgkey' | sudo -- gpg --batch --dearmor --yes --output '$@'

pkg.posix: /etc/apt/sources.list.d/nvidia-container-toolkit.list
/etc/apt/sources.list.d/nvidia-container-toolkit.list: /etc/apt/trusted.gpg.d/nvidia-container-toolkit.gpg
	sudo -- tee -- '$@' <<-'EOF'
	deb https://nvidia.github.io/libnvidia-container/stable/deb/$(GOARCH) /
	EOF

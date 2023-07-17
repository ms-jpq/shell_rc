.PHONY: curl
all: curl

$(TMP)/curl: $(TMP)
	mkdir -p -- '$@'


define ARCHIVE_TEMPLATE

$(TMP)/curl/$(1): $(TMP)/curl /usr/bin/curl /usr/bin/unzip
	URI='$(2)'
	if [[ '$(2)' =~ ^!! ]] && [[ "$$$$MACHTYPE" =~ aarch64 ]]; then
		touch -- '$$@'
	else
		./libexec/curl-unpack.sh "$$$${URI##!!}" '$$<'
	fi

$(BIN)/$(notdir $(1)): $(TMP)/curl/$(1)
	install --compare --backup -- '$$<' '$$@'

curl: $(BIN)/$(notdir $(1))

endef


define DEB_TEMPLATE

$(TMP)/curl/$(notdir $(2)): $(TMP)/curl /usr/bin/curl
	$(CURL) --output '$$@' -- '$(2)'

$(1): $(TMP)/curl/$(notdir $(2))
	dpkg --install -- '$$@'

endef


define CURL_ARCHIVES

dust-v0.8.6-$(MACHTYPE)-unknown-linux-gnu/dust https://github.com/bootandy/dust/releases/latest/download/dust-v0.8.6-$(MACHTYPE)-unknown-linux-gnu.tar.gz
fzf                                            https://github.com/junegunn/fzf/releases/latest/download/fzf-0.42.0-linux_$(GO_ARCH).tar.gz
gitui                                          https://github.com/extrawurst/gitui/releases/latest/download/gitui-linux-musl.tar.gz
gojq_v0.12.13_linux_$(GO_ARCH)/gojq            https://github.com/itchyny/gojq/releases/latest/download/gojq_v0.12.13_linux_$(GO_ARCH).tar.gz
htmlq                                          !!https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-linux.tar.gz
jless                                          !!https://github.com/PaulJuliusMartinez/jless/releases/latest/download/jless-v0.9.0-x86_64-unknown-linux-gnu.zip
lazygit                                        https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.38.2_Linux_$(GO_ARCH).tar.gz
posh-linux-$(GO_ARCH)                          https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$(GO_ARCH)
tokei                                          https://github.com/XAMPPRocky/tokei/releases/latest/download/tokei-$(MACHTYPE)-unknown-linux-gnu.tar.gz
xsc                                            !!https://github.com/BurntSushi/xsv/releases/latest/download/xsv-0.13.0-x86_64-unknown-linux-musl.tar.gz

endef

# /etc/apt/sources.list.d/   https://packages.microsoft.com/config/ubuntu/$(DPKG_ARCH)/packages-microsoft-prod.deb

define CURL_DEBS

/usr/bin/delta       https://github.com/dandavison/delta/releases/latest/download/git-delta_0.16.5_$(DPKG_ARCH).deb
/usr/bin/pastel      https://github.com/sharkdp/pastel/releases/latest/download/pastel_0.9.0_$(MACHTYPE).deb
/usr/bin/sad         https://github.com/ms-jpq/sad/releases/latest/download/$(MACHTYPE)-unknown-linux-gnu.deb
/usr/bin/tidy-viewer https://github.com/alexhallam/tv/releases/latest/download/tidy-viewer_1.5.2_$(DPKG_ARCH).deb
/usr/bin/watchexec   https://github.com/watchexec/watchexec/releases/latest/download/watchexec-1.22.3-$(MACHTYPE)-unknown-linux-gnu.deb

endef


CURL_ARCHIVES := $(shell tr -s ' ' '#' <<<'$(CURL_ARCHIVES)')
CURL_DEBS := $(shell tr -s ' ' '#' <<<'$(CURL_DEBS)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)
# $(call META_2D,CURL_DEBS,DEB_TEMPLATE)

.PHONY: curl deb deb-dep
all: curl deb

$(TMP)/curl: $(TMP)
	mkdir -p -- '$@'

deb-dep: | pkg
	$(APT_INSTALL) $^


define ARCHIVE_TEMPLATE
ifneq (aarch64!!,$(MACHTYPE)$(findstring !!,$(2)))

$(TMP)/curl/$(1): $(TMP)/curl /usr/bin/curl /usr/bin/unzip
	./libexec/curl-unpack.sh '$(subst !!,,$(2))' '$$<'

$(BIN)/$(notdir $(1)): $(TMP)/curl/$(1)
	install --compare --backup -- '$$<' '$$@'

curl: $(BIN)/$(notdir $(1))

endif
endef


define DEB_TEMPLATE
ifneq (aarch64!!,$(MACHTYPE)$(findstring !!,$(2)))

$(TMP)/curl/$(notdir $(2)): $(TMP)/curl /usr/bin/curl
	$(CURL) --output '$$@' -- '$(subst !!,,$(2))'

deb-dep: $(TMP)/curl/$(notdir $(2))
$(1): deb-dep
deb: $(1)

endif
endef


ifeq ($(MACHTYPE), aarch64)
	GITUI_TYPE := $(MACHTYPE)
else
	GITUI_TYPE := musl
endif


ifeq ($(MACHTYPE), aarch64)
	LAZY_TYPE := $(GOARCH)
else
	LAZY_TYPE := $(MACHTYPE)
endif


define CURL_ARCHIVES

dust-v0.8.6-$(MACHTYPE)-unknown-linux-gnu/dust https://github.com/bootandy/dust/releases/latest/download/dust-v0.8.6-$(MACHTYPE)-unknown-linux-gnu.tar.gz
fzf                                            https://github.com/junegunn/fzf/releases/latest/download/fzf-0.42.0-linux_$(GOARCH).tar.gz
gitui                                          https://github.com/extrawurst/gitui/releases/latest/download/gitui-linux-$(GITUI_TYPE).tar.gz
gojq_v0.12.13_linux_$(GOARCH)/gojq             https://github.com/itchyny/gojq/releases/latest/download/gojq_v0.12.13_linux_$(GOARCH).tar.gz
htmlq                                          !!https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-linux.tar.gz
jless                                          !!https://github.com/PaulJuliusMartinez/jless/releases/latest/download/jless-v0.9.0-x86_64-unknown-linux-gnu.zip
lazygit                                        https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.38.2_Linux_$(LAZY_TYPE).tar.gz
posh-linux-$(GOARCH)                           https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$(GOARCH)
tokei                                          https://github.com/XAMPPRocky/tokei/releases/latest/download/tokei-$(MACHTYPE)-unknown-linux-gnu.tar.gz
xsv                                            !!https://github.com/BurntSushi/xsv/releases/latest/download/xsv-0.13.0-x86_64-unknown-linux-musl.tar.gz

endef


define CURL_DEBS

/etc/apt/sources.list.d/microsoft-prod.list https://packages.microsoft.com/config/ubuntu/$(VERSION_ID)/packages-microsoft-prod.deb
/usr/bin/delta                              https://github.com/dandavison/delta/releases/latest/download/git-delta_0.16.5_$(GOARCH).deb
/usr/bin/pastel                             https://github.com/sharkdp/pastel/releases/latest/download/pastel_0.9.0_$(GOARCH).deb
/usr/bin/tidy-viewer                        !!https://github.com/alexhallam/tv/releases/latest/download/tidy-viewer_1.5.2_$(GOARCH).deb
/usr/bin/watchexec                          https://github.com/watchexec/watchexec/releases/latest/download/watchexec-1.22.3-$(MACHTYPE)-unknown-linux-gnu.deb
/usr/local/bin/sad                          https://github.com/ms-jpq/sad/releases/latest/download/$(MACHTYPE)-unknown-linux-gnu.deb

endef


CURL_ARCHIVES := $(shell tr -s ' ' '#' <<<'$(CURL_ARCHIVES)')
CURL_DEBS := $(shell tr -s ' ' '#' <<<'$(CURL_DEBS)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)
$(call META_2D,CURL_DEBS,DEB_TEMPLATE)

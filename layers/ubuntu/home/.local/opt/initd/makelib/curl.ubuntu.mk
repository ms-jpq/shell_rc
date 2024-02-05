.PHONY: deb
all: deb

APT_INSTALL := sudo -- env -- DEBIAN_FRONTEND=noninteractive apt-get install --yes

define ARCHIVE_TEMPLATE
ifneq (aarch64**,$(HOSTTYPE)$(findstring **,$2))

$(TP)/curl/$1: | $(TP)/curl /usr/bin/curl /usr/bin/jq /usr/bin/unzip
	./libexec/curl-unpack.sh '$(subst **,,$2)' '$(TP)/curl'

$(BIN)/$(notdir $1): | $(TP)/curl/$1
	install --backup -- '$(TP)/curl/$1' '$$@'

curl: $(BIN)/$(notdir $1)

endif
endef


define DEB_TEMPLATE
ifneq (aarch64**,$(HOSTTYPE)$(findstring **,$2))

$(TP)/curl/$(notdir $2): | $(TP)/curl /usr/bin/curl /usr/bin/jq
	$(CURL) --output '$$@' -- '$(subst **,,$2)'

deb: .WAIT $1
$1: | $(TP)/curl/$(notdir $2) pkg.posix
	$$(APT_INSTALL) -o DPkg::Lock::Timeout=-1 -- '$(TP)/curl/$(notdir $2)' </dev/null

endif
endef


ifeq ($(HOSTTYPE), aarch64)
GITUI_TYPE := $(HOSTTYPE)
else
GITUI_TYPE := musl
endif


ifeq ($(HOSTTYPE), aarch64)
LAZY_TYPE := $(GOARCH)
else
LAZY_TYPE := $(HOSTTYPE)
endif

V_BTM     =  $(shell $(GH_LATEST) ClementTsang/bottom)
V_DELTA   =  $(shell $(GH_LATEST) dandavison/delta)
V_DUST    =  $(shell $(GH_LATEST) bootandy/dust)
V_FZF     =  $(shell $(GH_LATEST) junegunn/fzf)
V_GOJQ    := $(shell $(GH_LATEST) itchyny/gojq)
V_JLESS   =  $(shell $(GH_LATEST) PaulJuliusMartinez/jless)
V_LAZYGIT =  $(patsubst v%,%,$(shell $(GH_LATEST) jesseduffield/lazygit))
V_PASTEL  =  $(patsubst v%,%,$(shell $(GH_LATEST) sharkdp/pastel))
V_S5CMD   =  $(patsubst v%,%,$(shell $(GH_LATEST) peak/s5cmd))
V_TV      =  $(shell $(GH_LATEST) alexhallam/tv)
V_WATCHEX =  $(patsubst v%,%,$(shell $(GH_LATEST) watchexec/watchexec))
V_XSV     =  $(shell $(GH_LATEST) BurntSushi/xsv)


define CURL_ARCHIVES

eza                                               https://github.com/eza-community/eza/releases/latest/download/eza_$(HOSTTYPE)-unknown-linux-gnu.tar.gz
dust-$(V_DUST)-$(HOSTTYPE)-unknown-linux-gnu/dust https://github.com/bootandy/dust/releases/latest/download/dust-$(V_DUST)-$(HOSTTYPE)-unknown-linux-gnu.tar.gz
fzf                                               https://github.com/junegunn/fzf/releases/latest/download/fzf-$(V_FZF)-linux_$(GOARCH).tar.gz
gitui                                             https://github.com/extrawurst/gitui/releases/latest/download/gitui-linux-$(GITUI_TYPE).tar.gz
gojq_$(V_GOJQ)_linux_$(GOARCH)/gojq               https://github.com/itchyny/gojq/releases/latest/download/gojq_$(V_GOJQ)_linux_$(GOARCH).tar.gz
htmlq                                             **https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-linux.tar.gz
jless                                             **https://github.com/PaulJuliusMartinez/jless/releases/latest/download/jless-$(V_JLESS)-x86_64-unknown-linux-gnu.zip
lazygit                                           https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_$(V_LAZYGIT)_Linux_$(LAZY_TYPE).tar.gz
posh-linux-$(GOARCH)                              https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$(GOARCH)
tokei                                             https://github.com/XAMPPRocky/tokei/releases/latest/download/tokei-$(HOSTTYPE)-unknown-linux-gnu.tar.gz
xsv                                               **https://github.com/BurntSushi/xsv/releases/latest/download/xsv-$(V_XSV)-x86_64-unknown-linux-musl.tar.gz

endef


define CURL_DEBS

/etc/apt/sources.list.d/microsoft-prod.list https://packages.microsoft.com/config/ubuntu/$(VERSION_ID)/packages-microsoft-prod.deb
/usr/bin/btm                                https://github.com/ClementTsang/bottom/releases/latest/download/bottom_$(V_BTM)_$(GOARCH).deb
/usr/bin/delta                              https://github.com/dandavison/delta/releases/latest/download/git-delta_$(V_DELTA)_$(GOARCH).deb
/usr/bin/pastel                             https://github.com/sharkdp/pastel/releases/latest/download/pastel_$(V_PASTEL)_$(GOARCH).deb
/usr/bin/s5cmd                              https://github.com/peak/s5cmd/releases/latest/download/s5cmd_$(V_S5CMD)_linux_$(GOARCH).deb
/usr/bin/tidy-viewer                        **https://github.com/alexhallam/tv/releases/latest/download/tidy-viewer_$(V_TV)_$(GOARCH).deb
/usr/bin/watchexec                          https://github.com/watchexec/watchexec/releases/latest/download/watchexec-$(V_WATCHEX)-$(HOSTTYPE)-unknown-linux-gnu.deb
/usr/local/bin/sad                          https://github.com/ms-jpq/sad/releases/latest/download/$(HOSTTYPE)-unknown-linux-gnu.deb

endef


CURL_ARCHIVES := $(shell tr -s -- ' ' '!' <<<'$(CURL_ARCHIVES)')
CURL_DEBS := $(shell tr -s -- ' ' '!' <<<'$(CURL_DEBS)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)
$(call META_2D,CURL_DEBS,DEB_TEMPLATE)

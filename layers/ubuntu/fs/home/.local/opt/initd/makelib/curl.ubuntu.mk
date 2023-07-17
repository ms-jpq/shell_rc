.PHONY: curl
all: curl

define ARCHIVE_TEMPLATE

curl: $(1)

$(1): /usr/bin/curl /usr/bin/unzip
	FILE='$(1)'
	./libexec/curl-archive.sh '$(2)' "$$$${FILE%/*}"

endef


define CURL_ARCHIVES

$(BIN)/fzf     https://github.com/junegunn/fzf/releases/latest/download/fzf-0.42.0-linux_$(DPKG_ARCH).tar.gz
$(BIN)/gitui   https://github.com/extrawurst/gitui/releases/latest/download/gitui-linux-musl.tar.gz
$(BIN)/htmlq   https://github.com/mgdm/htmlq/releases/latest/download/htmlq-$(MACHTYPE)-linux.tar.gz
$(BIN)/jless   https://github.com/PaulJuliusMartinez/jless/releases/latest/download/jless-v0.8.0-$(MACHTYPE)-unknown-linux-gnu.zip
$(BIN)/lazygit https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.38.2_Linux_$(MACHTYPE).tar.gz
$(BIN)/tokei   https://github.com/XAMPPRocky/tokei/releases/latest/download/tokei-$(MACHTYPE)-unknown-linux-gnu.tar.gz
$(BIN)/xsc     https://github.com/BurntSushi/xsv/releases/latest/download/xsv-0.13.0-$(MACHTYPE)-unknown-linux-musl.tar.gz

endef

CURL_ARCHIVES := $(shell tr -s ' ' '#' <<<'$(CURL_ARCHIVES)')

$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)

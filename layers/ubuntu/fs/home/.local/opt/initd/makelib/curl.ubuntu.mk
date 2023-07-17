.PHONY: curl
all: curl

$(TMP)/curl:
	mkdir -p -- '$@'


define ARCHIVE_TEMPLATE

$(TMP)/curl/$(1): $(TMP)/curl /usr/bin/curl /usr/bin/unzip
	URI='$(2)'
	if [[ '$(2)' =~ ^!! ]] && [[ "$$$$MACHTYPE" =~ aarch64 ]]; then
		touch -- '$$@'
	else
		./libexec/curl-archive.sh "$$$${URI##!!}" '$$<'
	fi

curl: $(TMP)/curl/$(1)

endef


define CURL_ARCHIVES

fzf     https://github.com/junegunn/fzf/releases/latest/download/fzf-0.42.0-linux_$(GO_ARCH).tar.gz
gitui   https://github.com/extrawurst/gitui/releases/latest/download/gitui-linux-musl.tar.gz
htmlq   !!https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-linux.tar.gz
jless   !!https://github.com/PaulJuliusMartinez/jless/releases/latest/download/jless-v0.9.0-x86_64-unknown-linux-gnu.zip
lazygit https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.38.2_Linux_$(GO_ARCH).tar.gz
tokei   https://github.com/XAMPPRocky/tokei/releases/latest/download/tokei-$(MACHTYPE)-unknown-linux-gnu.tar.gz
xsc     !!https://github.com/BurntSushi/xsv/releases/latest/download/xsv-0.13.0-x86_64-unknown-linux-musl.tar.gz

endef

CURL_ARCHIVES := $(shell tr -s ' ' '#' <<<'$(CURL_ARCHIVES)')

$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)

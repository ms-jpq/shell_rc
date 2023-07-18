.PHONY: curl
all: curl

$(TMP)/curl: $(TMP)
	mkdir -p -- '$@'


define ARCHIVE_TEMPLATE

$(TMP)/curl/$(1): $(TMP)/curl
	./libexec/curl-unpack.sh '$(subst !!,,$(2))' '$$<'

$(BIN)/$(notdir $(1)): $(TMP)/curl/$(1)
	install --backup -- '$$<' '$$@'

curl: $(BIN)/$(notdir $(1))

endef


define CURL_ARCHIVES

bat-v0.22.1-x86_64-pc-windows-msvc/bat.exe             https://github.com/sharkdp/bat/releases/latest/download/bat-v0.22.1-x86_64-pc-windows-msvc.zip
delta-0.16.5-x86_64-pc-windows-msvc/delta.exe          https://github.com/dandavison/delta/releases/latest/download/delta-0.16.5-x86_64-pc-windows-msvc.zip
duf.exe                                                https://github.com/muesli/duf/releases/latest/download/duf_0.8.1_Windows_x86_64.zip
dust-v0.8.6-x86_64-pc-windows-msvc/dust.exe            https://github.com/bootandy/dust/releases/latest/download/dust-v0.8.6-x86_64-pc-windows-msvc.zip
fd-v8.6.0-x86_64-pc-windows-msvc/fd.exe                https://github.com/sharkdp/fd/releases/latest/download/fd-v8.6.0-x86_64-pc-windows-msvc.zip
fzf.exe                                                https://github.com/junegunn/fzf/releases/latest/download/fzf-0.42.0-windows_amd64.zip
gitui.exe                                              https://github.com/extrawurst/gitui/releases/latest/download/gitui-win.tar.gz
htmlq.exe                                              https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-windows.zip
hyperfine-v1.15.0-x86_64-pc-windows-msvc/hyperfine.exe https://github.com/sharkdp/hyperfine/releases/latest/download/hyperfine-v1.15.0-x86_64-pc-windows-msvc.zip
lazygit.exe                                            https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.38.2_Windows_x86_64.zip
pastel-v0.9.0-x86_64-pc-windows-msvc/pastel.exe        https://github.com/sharkdp/pastel/releases/latest/download/pastel-v0.9.0-x86_64-pc-windows-msvc.zip
ripgrep-13.0.0-x86_64-pc-windows-msvc/rg.exe           https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-13.0.0-x86_64-pc-windows-msvc.zip
sad.exe                                                https://github.com/ms-jpq/sad/releases/latest/download/x86_64-pc-windows-msvc.zip
tokei.exe                                              https://github.com/XAMPPRocky/tokei/releases/latest/download/tokei-x86_64-pc-windows-msvc.exe
watchexec-1.22.3-x86_64-pc-windows-msvc/watchexec.exe  https://github.com/watchexec/watchexec/releases/latest/download/watchexec-1.22.3-x86_64-pc-windows-msvc.zip
xsv.exe                                                https://github.com/BurntSushi/xsv/releases/latest/download/xsv-0.13.0-x86_64-pc-windows-msvc.zip

endef


CURL_ARCHIVES := $(shell tr -s ' ' '#' <<<'$(CURL_ARCHIVES)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)

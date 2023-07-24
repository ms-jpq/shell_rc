.PHONY: curl
all: curl

$(TMP)/curl: $(TMP)
	mkdir -p -- '$@'


define ARCHIVE_TEMPLATE

$(TMP)/curl/$1: $(TMP)/curl
	./libexec/curl-unpack.sh '$(subst !!,,$2)' '$$<'

$(BIN)/$(notdir $1): $(TMP)/curl/$1
	install --backup -- '$$<' '$$@'

curl: $(BIN)/$(notdir $1)

endef


define CURL_ARCHIVES

bat-v0.23.0-x86_64-pc-windows-msvc/bat.exe             https://github.com/sharkdp/bat/releases/latest/download/bat-v0.23.0-x86_64-pc-windows-msvc.zip
duf.exe                                                https://github.com/muesli/duf/releases/latest/download/duf_0.8.1_Windows_x86_64.zip
dust-v0.8.6-x86_64-pc-windows-msvc/dust.exe            https://github.com/bootandy/dust/releases/latest/download/dust-v0.8.6-x86_64-pc-windows-msvc.zip
gitui.exe                                              https://github.com/extrawurst/gitui/releases/latest/download/gitui-win.tar.gz
htmlq.exe                                              https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-windows.zip
pastel-v0.9.0-x86_64-pc-windows-msvc/pastel.exe        https://github.com/sharkdp/pastel/releases/latest/download/pastel-v0.9.0-x86_64-pc-windows-msvc.zip
sad.exe                                                https://github.com/ms-jpq/sad/releases/latest/download/x86_64-pc-windows-msvc.zip
tokei-x86_64-pc-windows-msvc.exe                       https://github.com/XAMPPRocky/tokei/releases/latest/download/tokei-x86_64-pc-windows-msvc.exe
watchexec-1.22.3-x86_64-pc-windows-msvc/watchexec.exe  https://github.com/watchexec/watchexec/releases/latest/download/watchexec-1.22.3-x86_64-pc-windows-msvc.zip
xsv.exe                                                https://github.com/BurntSushi/xsv/releases/latest/download/xsv-0.13.0-x86_64-pc-windows-msvc.zip

endef


CURL_ARCHIVES := $(shell tr -s ' ' '#' <<<'$(CURL_ARCHIVES)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)

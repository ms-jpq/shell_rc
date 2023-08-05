define ARCHIVE_TEMPLATE

$(TP)/curl/$1: | $(TP)/curl
	./libexec/curl-unpack.sh '$(subst **,,$2)' '$$|'

$(BIN)/$(notdir $1): | $(TP)/curl/$1
	install --backup -- '$(call UNIX_2_NT,$(TP)/curl/$1)' '$$@'

curl: $(BIN)/$(notdir $1)

endef


V_BAT     := $(shell $(GH_LATEST) sharkdp/bat)
V_DUST    := $(shell $(GH_LATEST) bootandy/dust)
V_PASTEL  := $(shell $(GH_LATEST) sharkdp/pastel)
V_WATCHEX := $(patsubst v%,%,$(shell $(GH_LATEST) watchexec/watchexec))
V_XSV     =  $(shell $(GH_LATEST) BurntSushi/xsv)


define CURL_ARCHIVES

bat-$(V_BAT)-x86_64-pc-windows-msvc/bat.exe                 https://github.com/sharkdp/bat/releases/latest/download/bat-$(V_BAT)-x86_64-pc-windows-msvc.zip
dust-$(V_DUST)-x86_64-pc-windows-msvc/dust.exe              https://github.com/bootandy/dust/releases/latest/download/dust-$(V_DUST)-x86_64-pc-windows-msvc.zip
gitui.exe                                                   https://github.com/extrawurst/gitui/releases/latest/download/gitui-win.tar.gz
htmlq.exe                                                   https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-windows.zip
pastel-$(V_PASTEL)-x86_64-pc-windows-msvc/pastel.exe        https://github.com/sharkdp/pastel/releases/latest/download/pastel-$(V_PASTEL)-x86_64-pc-windows-msvc.zip
sad.exe                                                     https://github.com/ms-jpq/sad/releases/latest/download/x86_64-pc-windows-msvc.zip
tokei-x86_64-pc-windows-msvc.exe                            https://github.com/XAMPPRocky/tokei/releases/latest/download/tokei-x86_64-pc-windows-msvc.exe
watchexec-$(V_WATCHEX)-x86_64-pc-windows-msvc/watchexec.exe https://github.com/watchexec/watchexec/releases/latest/download/watchexec-$(V_WATCHEX)-x86_64-pc-windows-msvc.zip
xsv.exe                                                     https://github.com/BurntSushi/xsv/releases/latest/download/xsv-$(V_XSV)-x86_64-pc-windows-msvc.zip

endef


CURL_ARCHIVES := $(shell tr -s ' ' '!' <<<'$(CURL_ARCHIVES)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)

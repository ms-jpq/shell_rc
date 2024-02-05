define ARCHIVE_TEMPLATE

$(TP)/curl/$1: | $(TP)/curl
	./libexec/curl-unpack.sh '$(subst **,,$2)' '$$|'

$(BIN)/$(notdir $1): | $(TP)/curl/$1
	install --backup -- '$(call UNIX_2_NT,$(TP)/curl/$1)' '$$@'

curl: $(BIN)/$(notdir $1)

endef


ifeq ($(HOSTTYPE), aarch64)
S5_TYPE := $(GOARCH)
else
S5_TYPE := 64bit
endif

V_S5CMD   =  $(patsubst v%,%,$(shell $(GH_LATEST) peak/s5cmd))
V_WATCHEX := $(patsubst v%,%,$(shell $(GH_LATEST) watchexec/watchexec))
V_XSV     =  $(shell $(GH_LATEST) BurntSushi/xsv)


define CURL_ARCHIVES

gitui.exe                                                   https://github.com/extrawurst/gitui/releases/latest/download/gitui-win.tar.gz
gping.exe                                                   https://github.com/orf/gping/releases/latest/download/gping-Windows-x86_64.zip
htmlq.exe                                                   https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-windows.zip
s5cmd.exe                                                   https://github.com/peak/s5cmd/releases/latest/download/s5cmd_$(V_S5CMD)_Windows-$(S5_TYPE).zip
sad.exe                                                     https://github.com/ms-jpq/sad/releases/latest/download/x86_64-pc-windows-msvc.zip
watchexec-$(V_WATCHEX)-x86_64-pc-windows-msvc/watchexec.exe https://github.com/watchexec/watchexec/releases/latest/download/watchexec-$(V_WATCHEX)-x86_64-pc-windows-msvc.zip
xsv.exe                                                     https://github.com/BurntSushi/xsv/releases/latest/download/xsv-$(V_XSV)-x86_64-pc-windows-msvc.zip

endef


CURL_ARCHIVES := $(shell tr -s -- ' ' '!' <<<'$(CURL_ARCHIVES)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)

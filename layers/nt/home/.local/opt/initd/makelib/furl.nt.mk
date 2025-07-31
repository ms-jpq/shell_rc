define ARCHIVE_TEMPLATE

$(TP)/curl/$1: | $(TP)/curl
	./libexec/curl-unpack.sh '$(subst **,,$2)' '$$|'

$(BIN)/$(notdir $1): | $(TP)/curl/$1
	install --backup -- '$(call UNIX_2_NT,$(TP)/curl/$1)' '$$@'

curl: $(BIN)/$(notdir $1)

endef

ifeq ($(HOSTTYPE), aarch64)
DIFFN_TYPE := arm64
S5_TYPE    := $(GOARCH)
else
DIFFN_TYPE := $(HOSTTYPE)
S5_TYPE    := 64bit
endif

V_WATCHEX := $(patsubst v%,%,$(shell $(GH_LATEST) watchexec/watchexec))


define CURL_ARCHIVES

diffnav.exe                                                 https://github.com/dlvhdr/diffnav/releases/latest/download/diffnav_Windows_$(DIFFN_TYPE).zip
watchexec-$(V_WATCHEX)-x86_64-pc-windows-msvc/watchexec.exe https://github.com/watchexec/watchexec/releases/latest/download/watchexec-$(V_WATCHEX)-x86_64-pc-windows-msvc.zip

endef

# gping.exe                                                   https://github.com/orf/gping/releases/latest/download/gping-Windows-x86_64.zip

CURL_ARCHIVES := $(shell tr -s -- ' ' '!' <<<'$(CURL_ARCHIVES)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)

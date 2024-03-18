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

define CURL_ARCHIVES

posh-linux-$(GOARCH) https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$(GOARCH)

endef

define CURL_DEBS

/etc/apt/sources.list.d/microsoft-prod.list https://packages.microsoft.com/config/ubuntu/$(VERSION_ID)/packages-microsoft-prod.deb

endef

CURL_ARCHIVES := $(shell tr -s -- ' ' '!' <<<'$(CURL_ARCHIVES)')
CURL_DEBS := $(shell tr -s -- ' ' '!' <<<'$(CURL_DEBS)')
$(call META_2D,CURL_ARCHIVES,ARCHIVE_TEMPLATE)
$(call META_2D,CURL_DEBS,DEB_TEMPLATE)

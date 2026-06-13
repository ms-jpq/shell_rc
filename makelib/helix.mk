.PHONY: helix clobber.helix

clobber: clobber.helix
all: helix

HELIX := ./layers/posix/home/.config/helix

$(VAR)/helix: | $(VAR)
	./libexec/git-sync.sh https://github.com/helix-editor/helix '$@'

$(VAR)/helix.lang.toml: | $(VAR)/helix
	cp -- '$|/languages.toml' '$@'

clobber.helix:
	rm -vfr -- $(HELIX)/languages.toml $(VAR)/helix.lang.toml $(VAR)/helix

helix: $(HELIX)/languages.toml
$(HELIX)/languages.toml: $(HELIX)/libexec/languages.sh $(HELIX)/libexec/languages.jq $(VAR)/helix.lang.toml $(HELIX)/languages.json | $(VENV)/$(PY_BIN)
	'$(HELIX)/libexec/languages.sh'

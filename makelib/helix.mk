.PHONY: helix clobber.helix

clobber: clobber.helix
all: helix

HELIX := ./layers/posix/home/.config/helix

$(VAR)/helix.lang.toml:
	URI='https://raw.githubusercontent.com/helix-editor/helix/refs/heads/master/languages.toml'
	$(CURL) --output '$@' -- "$$URI"

clobber.helix:
	rm -vfr -- $(HELIX)/languages.toml

helix: $(HELIX)/languages.toml
$(HELIX)/languages.toml: $(HELIX)/libexec/languages.sh $(HELIX)/libexec/languages.jq $(VAR)/helix.lang.toml $(HELIX)/languages.json | $(VENV)/$(PY_BIN)
	'$(HELIX)/libexec/languages.sh'

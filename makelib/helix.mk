.PHONY: helix clobber.helix

clobber: clobber.helix
all: helix

HELIX := ./layers/posix/home/.config/helix
HELIX_RELEASE := 25.07.1

$(VAR)/helix.lang.toml:
	URI='https://raw.githubusercontent.com/helix-editor/helix/refs/tags/$(HELIX_RELEASE)/languages.toml'
	$(CURL) --output '$@' -- "$$URI"

clobber.helix:
	rm -vfr -- $(HELIX)/languages.toml

helix: $(HELIX)/languages.toml
$(HELIX)/languages.toml: $(VENV)/$(PY_BIN) $(HELIX)/libexec/lang.py $(VAR)/helix.lang.toml $(HELIX)/languages.json
	'$</python3' '$(HELIX)/libexec/lang.py'

.PHONY: helix clobber.helix

clobber: clobber.helix

HELIX := ./layers/posix/home/.config/helix

clobber.helix:
	rm -vfr -- $(HELIX)/languages.toml

helix: $(HELIX)/languages.toml
$(HELIX)/languages.toml: $(VENV)/$(PY_BIN) $(HELIX)/libexec/lang.py $(HELIX)/languages.json
	'$</python' '$(HELIX)/libexec/lang.py'

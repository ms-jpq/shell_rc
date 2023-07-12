.PHONY: pipx

PIPX := $(LOCAL)/pipx/venvs

# $(OPT)/pipx:
# 	python3 -m venv --upgrade -- "$@"

# $(OPT)/pipx/bin/pipx:
# 	'$(OPT)/pipx/bin/pip' install --require-virtualenv --upgrade -- pipx

# pipx: $(PIPX)/gay
# $(PIPX)/gay: $(OPT)/pipx/bin/pipx
# 	'$<' install -- gay

# pipx: $(PIPX)/gay
# $(PIPX)/gay: $(OPT)/pipx/bin/pipx
# 	'$<' install -- gay

# pipx: $(PIPX)/gay
# $(PIPX)/gay: $(OPT)/pipx/bin/pipx
# 	'$<' install -- gay


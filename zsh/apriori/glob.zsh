#!/usr/bin/env -S -- bash

setopt -- extended_glob   # More glob?
setopt -- glob_dots       # Match .*
setopt -- glob_star_short # Globstar
setopt -- mark_dirs       # Auto append / to glob results
setopt -- null_glob       # No glob literal

#!/usr/bin/env -S -- bash

setopt -- bad_pattern   # print error message
setopt -- dotglob       # glob dotfiles
setopt -- extended_glob # more glob?
setopt -- no_case_glob  # case insensitive
setopt -- no_case_match # case insensitive
setopt -- nullglob      # no glob literal

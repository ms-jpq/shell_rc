#!/usr/bin/env -S -- bash

bind -- '"\e[A": history-search-backward'
bind -- '"\e[B": history-search-forward'
bind -- '"\e[C": forward-char'
bind -- '"\e[D": backward-char'

bind -- 'Space:magic-space' # History Expansion

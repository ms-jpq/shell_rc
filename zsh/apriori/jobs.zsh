#!/usr/bin/env -S -- bash

setopt -- check_jobs         # Prevent exit when jobs present
setopt -- check_running_jobs # Prevent exit when running jobs present
setopt -- hup                # Send SIGHUP on exit
setopt -- long_list_jobs     # Verbose job listing
setopt -- pipe_fail          # Exit status of right most !0

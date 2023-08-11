#!/usr/bin/env -S -- bash

shopt -s -- checkjobs # Prevent exit with jobs
shopt -s -- huponexit # Send SIGHUP to jobs on exit
shopt -s -- pipefail  # Exit status of right most !0

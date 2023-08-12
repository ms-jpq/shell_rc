#!/usr/bin/env -S -- bash

set -o pipefail       # Exit status of right most !0
shopt -s -- checkjobs # Prevent exit with jobs
shopt -s -- huponexit # Send SIGHUP to jobs on exit

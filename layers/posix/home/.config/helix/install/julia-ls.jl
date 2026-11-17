#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar
#=
if [[ -n ${CI:-} ]]; then
  exit
fi

if ! command -v -- julia > /dev/null; then
  exit
fi
export -- JULIA_DEPOT_PATH="$LIB/depot"
mkdir -v -p -- "$JULIA_DEPOT_PATH"
exec -- julia --project="$LIB" "$0" "$@"
=#

using Pkg;

pkg = "LanguageServer"

Pkg.add(pkg)
Pkg.update(pkg)

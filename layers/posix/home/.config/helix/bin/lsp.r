#!/usr/bin/env -S -- Rscript

{
  home <- path.expand("~")
  lib <- file.path(home, ".cache", "helix-rt", "more", "lsp.r", "lib")
  .libPaths(c(.libPaths(), lib))
}

languageserver::run()

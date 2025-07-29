#!/usr/bin/env -S -- Rscript

{
  lsr <- path_home(".config", "nvim", "var", "lib", "lsr")
  .libPaths(c(.libPaths(), lib))
}

styler::style_file(commandArgs(trailingOnly = TRUE))

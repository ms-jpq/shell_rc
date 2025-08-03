#!/usr/bin/env -S -- Rscript

{
  home <- path.expand("~")
  lib <- file.path(home, ".cache", "helix-rt", "more", "lsp.r", "lib")
  .libPaths(c(.libPaths(), lib))
}

lines_in <- readLines(file("stdin"))
tmp <- paste(tempfile(), "r", sep = ".")
writeLines(lines_in, con = tmp)

invisible(capture.output(styler::style_file(c(tmp))))
lines_out <- readLines(tmp)
invisible(file.remove(tmp))
writeLines(lines_out)

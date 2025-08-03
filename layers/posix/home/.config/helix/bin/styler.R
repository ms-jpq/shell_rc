#!/usr/bin/env -S -- Rscript

{
  home <- path.expand("~")
  lib <- file.path(home, ".cache", "helix-rt", "more", "lsp.r", "lib")
  .libPaths(c(.libPaths(), lib))
}

tmp <- paste(tempfile(), "r", sep = ".")

tryCatch({
  writeLines(readLines(file("stdin")), con = tmp)
  invisible(capture.output(styler::style_file(c(tmp))))
  lines_out <- readLines(tmp)
  writeLines(readLines(tmp))
}, finally = {
  invisible(file.remove(tmp))
})

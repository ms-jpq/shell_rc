function rgl {
  rg --line-buffered --pretty "$@" | less
}

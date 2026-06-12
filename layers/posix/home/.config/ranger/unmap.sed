#!/usr/bin/env -S -- sed -E -n -f

s/^map[[:space:]]+((<[^>]+>|[^<[:space:]]){2,})[[:space:]].*/unmap \1/p
s/^cmap[[:space:]]+((<[^>]+>|[^<[:space:]]){2,})[[:space:]].*/cunmap \1/p
s/^pmap[[:space:]]+((<[^>]+>|[^<[:space:]]){2,})[[:space:]].*/punmap \1/p
s/^tmap[[:space:]]+((<[^>]+>|[^<[:space:]]){2,})[[:space:]].*/untmap \1/p

/^copy(c|p|t)?map[[:space:]]/ {
  s/^copymap[[:space:]]+[^[:space:]]+/unmap/
  s/^copycmap[[:space:]]+[^[:space:]]+/cunmap/
  s/^copypmap[[:space:]]+[^[:space:]]+/punmap/
  s/^copytmap[[:space:]]+[^[:space:]]+/untmap/
  s/[[:space:]]+/ /g
  s/$/ /
  :strip
  s/ (<[^>]+>|[^<[:space:]]) / /g
  t strip
  s/ +$//
  / / p
}

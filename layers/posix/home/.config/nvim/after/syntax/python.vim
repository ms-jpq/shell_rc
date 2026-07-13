syntax match pyImport '^\s*\zs\<import\>' conceal cchar=↓
syntax match pyFrom '^\s*\zs\%(yield\_s\+\)\@<!\<from\>' conceal cchar=→

syntax match pyCommentEdge '^\s*\zs#' conceal cchar=│

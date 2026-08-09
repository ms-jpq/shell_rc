syntax match pyShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match pyShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match pyImport '^\s*\zs\<import\>' conceal cchar=↓
syntax match pyFromImport '\(from\s\+\S\+\s\+\)\@<=\<import\>' conceal cchar=↓
syntax match pyFrom '^\s*\zs\%(yield\_s\+\)\@<!\<from\>' conceal cchar=→

syntax match pyCommentEdge  '^\s*\zs#\ze!\@!' conceal cchar=│
syntax match pyReplResponse '^\s*\zs#\s*|\ze\%(\s\|$\)' conceal cchar=┇

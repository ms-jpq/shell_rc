syntax match shShebangHash '\%1l^#\ze!' conceal cchar=‼
syntax match shShebangBang '\%1l\(^#\)\@<=!' conceal cchar= 

syntax match shOpen "^\s*\zs\<\%(do\|then\)\>" conceal cchar=⌈
syntax match shOpenSep ';\ze\s*\<\%(do\|then\)\>' conceal nextgroup=shOpen skipwhite
syntax keyword shOpen do then contained conceal cchar=⌈
syntax match shIn "case\s\+\S\+\s\+\zs\<in\>" conceal cchar=⌈

syntax match shDone "^\s*\zs\<done\>" conceal cchar=⌋
syntax match shEsac "^\s*\zs\<esac\>" conceal cchar=⌋
syntax match shFi "^\s*\zs\<fi\>" conceal cchar=⌋

syntax match shCommentEdge  '^\s*\zs#\ze!\@!' conceal cchar=│
syntax match shReplResponse '^\s*\zs#\s*|' conceal cchar=┇

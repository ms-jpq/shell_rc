syntax match shDo "\(^\s*\|;\s*\)\zs\<do\>" conceal cchar=⌈
syntax match shIn "case\s\+\S\+\s\+\zs\<in\>" conceal cchar=⌈
syntax match shThen "\(^\s*\|;\s*\)\zs\<then\>" conceal cchar=⌈

syntax match shDone "^\s*\zs\<done\>" conceal cchar=⌋
syntax match shEsac "^\s*\zs\<esac\>" conceal cchar=⌋
syntax match shFi "^\s*\zs\<fi\>" conceal cchar=⌋

syntax match shCommentEdge '^\s*\zs#\ze!\@!' conceal cchar=│

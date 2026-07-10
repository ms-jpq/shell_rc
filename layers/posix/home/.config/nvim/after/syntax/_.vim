syntax match ConcealDot "\.\.\." conceal cchar=…

syntax match ConcealGE ">=" conceal cchar=≥
syntax match ConcealLE "<=" conceal cchar=≤
syntax match ConcealNE "!=" conceal cchar=≠

syntax match ConcealLArr "\<\zs<-\ze\>" conceal cchar=←
syntax match ConcealRArr "\<\zs->\ze\>" conceal cchar=→

syntax match ConcealRE "\<\zs=>\ze\>" conceal cchar=▶

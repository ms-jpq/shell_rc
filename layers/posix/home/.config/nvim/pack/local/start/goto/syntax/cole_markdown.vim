syntax match mdQuote "\%(^\s*\|[>|]\s\+\)\@<=\zs>\ze\%(\s\||\%(\s\|$\)\|$\)" conceal cchar=┃

syntax match mdCommentOpen  "^\s*\zs<!--\ze\s" conceal cchar=│
syntax match mdCommentClose "\%(^\s*<!--.*\)\@<=\s*-->\s*$" conceal
syntax match mdReplResponse "\%(^\s*<!--\s*\)\@<=|\ze\%(\s\|$)" conceal cchar=┇

syntax match mdDash "^\s*\zs-\ze\%( \|$\)"  conceal cchar=*
syntax match mdPlus "^\s*\zs+\ze\%( \|$\)"  conceal cchar=◆
syntax match mdStar "^\s*\zs\*\ze\%( \|$\)" conceal cchar=✱

syntax match mdHrDash "-" contained conceal cchar=━
syntax match mdHrLine "^\s*-\{3,}\s*$" contains=mdHrDash

syntax match mdHrStar "\*" contained conceal cchar=─
syntax match mdHrStarLine "^\s*\*\{3,}\s*$" contains=mdHrStar

syntax match mdHrUnder "_" contained conceal cchar=╌
syntax match mdHrUnderLine "^\s*_\{3,}\s*$" contains=mdHrUnder

syntax match mdH1Hash "#" contained conceal cchar=█
syntax match mdH1 '^\s*\zs#\{1}\ze ' contains=mdH1Hash

syntax match mdH2Hash "#" contained conceal cchar=▓
syntax match mdH2 '^\s*\zs#\{2}\ze ' contains=mdH2Hash

syntax match mdH3Hash "#" contained conceal cchar=▒
syntax match mdH3 '^\s*\zs#\{3}\ze ' contains=mdH3Hash

syntax match mdH4Hash "#" contained conceal cchar=░
syntax match mdH4 '^\s*\zs#\{4}\ze ' contains=mdH4Hash

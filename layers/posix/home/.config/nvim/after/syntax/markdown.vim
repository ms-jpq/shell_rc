syntax match mdQuote "^\s*>\ze " conceal cchar=▎
syntax match mdDash "^\s*-\ze " conceal cchar=✱
syntax match mdStar "^\s*\*\ze " conceal cchar=☸

syntax match mdHrDash "-" contained conceal cchar=╌
syntax match mdHrLine "^\s*-\{3,}\s*$" contains=mdHrDash

syntax match mdHrStar "\*" contained conceal cchar=─
syntax match mdHrStarLine "^\s*\*\{3,}\s*$" contains=mdHrStar

syntax match mdHrUnder "_" contained conceal cchar=━
syntax match mdHrUnderLine "^\s*_\{3,}\s*$" contains=mdHrUnder

syntax match mdQuote "^\s*>\ze " conceal cchar=▎
syntax match mdDash "^\s*-\ze " conceal cchar=✱
syntax match mdStar "^\s*\*\ze " conceal cchar=☸

syntax match mdHrDash "-" contained conceal cchar=─
syntax match mdHrLine "^\s*-\{3,}\s*$" contains=mdHrDash

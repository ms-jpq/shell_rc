function s:colours()
  highlight! Conceal               guifg=NONE    guibg=NONE ctermfg=NONE ctermbg=NONE

  highlight  HighlightedyankRegion cterm=reverse gui=reverse
  highlight! CursorLine            guibg=#eae0f1 ctermbg=253
  highlight! EndOfBuffer           guibg=NONE    ctermbg=NONE
  highlight! Normal                guibg=NONE    ctermbg=NONE
  highlight! NormalNC              guibg=NONE    ctermbg=NONE
  highlight! SignColumn            guibg=NONE    ctermbg=NONE
  highlight! TreesitterContext     guibg=#C5DFEA ctermbg=254
  highlight! VertSplit             guibg=NONE    ctermbg=NONE
  highlight! link                  CursorColumn  CursorLine
  highlight! link                  MatchParen    Search
  highlight! link                  TabLineFill   Normal
  highlight! link                  WinSeparator  LineNr
endfunction

augroup theme_colours
  autocmd!
  autocmd ColorScheme * call s:colours()
augroup END
call s:colours()

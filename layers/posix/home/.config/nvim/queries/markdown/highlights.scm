;; extends

((block_quote) @comment
  (#lua-match? @comment "^>%s*|"))

((block_quote) @constant @markup.strong
  (#lua-match? @constant "^>%s*|%s*>>>"))

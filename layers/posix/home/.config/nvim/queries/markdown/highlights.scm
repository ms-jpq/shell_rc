;; extends

((block_quote) @comment
  (#lua-match? @comment "^>%s*|"))

((block_quote) @constant
  (#lua-match? @constant "^>%s*|%s*>>>"))

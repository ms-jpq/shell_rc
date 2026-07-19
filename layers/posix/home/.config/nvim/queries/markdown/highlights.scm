;; extends

((block_quote) @comment
  (#lua-match? @comment "^>%s*|"))

((block_quote) @keyword.directive
  (#lua-match? @keyword.directive "^>%s*|%s*>>>"))

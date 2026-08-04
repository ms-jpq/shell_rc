;; extends

(pipe_table_header "|" @markup.table.separator
  (#set! conceal "│"))

(pipe_table_row "|" @markup.table.separator
  (#set! conceal "│"))

(pipe_table_delimiter_row "|" @markup.table.separator
  (#set! conceal "│"))

(pipe_table_delimiter_cell "-" @markup.table.separator
  (#set! conceal "─"))

((pipe_table_align_left) @markup.table.separator
  (#set! conceal "╶"))

((pipe_table_align_right) @markup.table.separator
  (#set! conceal "╴"))

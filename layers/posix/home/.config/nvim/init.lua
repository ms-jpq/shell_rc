Go = {}

require("go.bookmark")
require("go.checktime")
require("go.clipboard")
require("go.commands")
require("go.cursor")
require("go.keymap")
require("go.lsp")
require("go.misc")
require("go.operators.casing")
require("go.operators.replace")
require("go.operators.search")
require("go.opts")
require("go.paths")
require("go.plugins")
require("go.search")
require("go.session")
require("go.status_line")
require("go.text_objects.entire")
require("go.text_objects.indent")
require("go.text_objects.line")
require("go.text_objects.move")
require("go.text_objects.sort")
require("go.theme")
require("go.whitespace")
require("go.windows")
require("go.formatter")

for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_get_name(buf) == "" then
    vim.bo[buf].buftype = "nofile"
  end
end

require("go.pack")

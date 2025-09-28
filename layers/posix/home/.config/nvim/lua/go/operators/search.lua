local lib = require("go")
local to = require("go.text_objects")

local magic_escape = function(text)
  return vim.fn.escape(text, "\\/\n\r\t")
end

local selected_text = function(visual_type)
  local row1, col1, row2, col2 = to.operator_marks(0, visual_type)
  local lines = vim.api.nvim_buf_get_text(0, row1, col1, row2, col2, {})
  local text = table.concat(lines, lib.buf_linefeed(0))

  return text
end

Go.op_buf_edit = function(visual_type)
  local text = selected_text(visual_type)
  local escaped = magic_escape(text)
  local cmd = [[:%s/\V]] .. escaped .. [[//g<left><left>]]

  vim.api.nvim_input(cmd)
end

vim.keymap.set("n", "gs", [[<cmd>set opfunc=v:lua.Go.op_buf_edit<cr>g@]])
vim.keymap.set("x", "gs", to.norm .. [[<cmd>lua Go.op_buf_edit(nil)<cr>]])

-- very magic
vim.keymap.set("n", "gS", [[:%s/\v//g<left><left><left>]])

local searcher = function(cmd)
  return function(visual_type)
    local text = selected_text(visual_type)
    local escaped = magic_escape(text)
    vim.fn.setreg("/", escaped)
    vim.opt.hlsearch = true
    local input = [[<cmd>]] .. cmd .. " " .. text .. [[<cr>]]
    vim.api.nvim_input(input)
  end
end

Go.op_blines = searcher("BLines")
Go.op_rg = searcher("RG")

for key, val in pairs {op_blines = "gf", op_rg = "gF"} do
  vim.keymap.set("n", val, [[<cmd>set opfunc=v:lua.Go.]] .. key .. [[<cr>g@]], {nowait = true, noremap = true})
  vim.keymap.set("x", val, to.norm .. [[<cmd>lua Go.]] .. key .. [[(nil)<cr>]], {nowait = true, noremap = true})
end

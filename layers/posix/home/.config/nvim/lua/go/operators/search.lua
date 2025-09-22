local lib = require("go")
local to = require("go.text_objects")

local magic_escape = function(text)
  local l1 = string.gsub(text, [[\]], [[\\]])
  local l2 = string.gsub(l1, [[/]], [[\/]])
  local l3 = string.gsub(l2, "\n", [[\n]])
  local l4 = string.gsub(l3, "\r", [[\r]])
  local l5 = string.gsub(l4, "\t", [[\t]])
  return l5
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

vim.keymap.set(
  "n",
  "gs",
  [[<cmd>set opfunc=v:lua.Go.op_buf_edit<cr>g@]],
  {noremap = true}
)
vim.keymap.set(
  "v",
  "gs",
  to.norm .. [[<cmd>lua Go.op_buf_edit(vim.NIL)<cr>]],
  {noremap = true}
)

-- very magic
vim.keymap.set("n", "gS", [[:%s/\v//g<left><left><left>]], {noremap = true})

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
  vim.keymap.set(
    "n",
    val,
    [[<cmd>set opfunc=v:lua.Go.]] .. key .. [[<cr>g@]],
    {nowait = true, noremap = true}
  )
  vim.keymap.set(
    "v",
    val,
    to.norm .. [[<cmd>lua Go.]] .. key .. [[(vim.NIL)<cr>]],
    {nowait = true, noremap = true}
  )
end

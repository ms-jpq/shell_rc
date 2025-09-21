local to = require("go.text_objects")

local p_indent = function(line, tabsize)
  local match = string.match(line, [[^%s+]])
  if match == nil then
    return 0
  end

  local tabs = {}
  for _ = 1, tabsize do
    table.insert(tabs, " ")
  end
  local subbed = string.gsub(match, "\t", table.concat(tabs, ""))
  return #subbed
end

local p_inside = function(init_lv, tabsize, lines)
  local n = 0

  return n
end

Go.op_indent = function(is_inside)
  local row = unpack(vim.api.nvim_win_get_cursor(0))
  local tabsize = vim.bo.tabstop
end

local cmd = function(hold)
  return [[<cmd>lua Go.op_indent(]] .. tostring(hold) .. [[)<cr>]]
end

-- vim.keymap.set("o", "ii", cmd(true), {noremap = true})
-- vim.keymap.set("o", "ai", cmd(false), {noremap = true})
-- vim.keymap.set("v", "ii", to.norm .. cmd(true), {noremap = true})
-- vim.keymap.set("v", "ai", to.norm .. cmd(false), {noremap = true})

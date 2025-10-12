local lib = require("go")
local to = require("go.text_objects")

-- join only add 1 space
vim.opt.joinspaces = true

-- insert spaces instead of tabs
vim.opt.expandtab = true

-- smart indentation level
vim.opt.smarttab = true

local set_tabsize = function(tabsize)
  for _, key in pairs {"tabstop", "softtabstop", "shiftwidth"} do
    vim.opt[key] = tabsize
  end
end

set_tabsize(2)

local detect_tabs = function()
  local count = vim.api.nvim_buf_line_count(0)
  local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(count, 99), true)

  local leading_tabs = 0
  local leading_spaces = 0

  for _, line in pairs(lines) do
    if vim.startswith(line, "\t") then
      leading_tabs = leading_tabs + 1
    elseif vim.startswith(line, " ") then
      leading_spaces = leading_spaces + 1
    end
  end

  if leading_tabs > leading_spaces then
    vim.bo.expandtab = false
  end

  local indent_lvs = {}
  for ts = 2, 4 do
    local divisibility = 0
    for _, line in pairs(lines) do
      local indent_lv = to.p_indent(line, ts)
      if indent_lv % ts == 0 then
        divisibility = divisibility + 1
      end
    end
    table.insert(indent_lvs, {ts})
  end

  table.sort(
    indent_lvs,
    function(lhs, rhs)
      local lt, ld = unpack(lhs)
      local rt, rd = unpack(rhs)

      if ld == rd then
        return lt < rt
      else
        return ld > rd
      end
    end
  )

  local winner = unpack(indent_lvs)
  local _, tabsize = unpack(winner)
  set_tabsize(tabsize)
end

vim.api.nvim_create_autocmd({"BufReadPost"}, {group = lib.group, callback = detect_tabs})

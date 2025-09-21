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
end

vim.api.nvim_create_autocmd({"BufReadPost"}, {callback = detect_tabs})

local async = require "go.async"
local lib = require "go.lib"
local to = require "go.text_objects"

-- show invisible characters
vim.opt.list = true
vim.opt.listchars = { trail = "·", nbsp = "␣", tab = "→ " }

-- merge spaces on join
vim.opt.joinspaces = true

-- insert spaces instead of tabs
vim.opt.expandtab = true

-- smart indentation level
vim.opt.smarttab = true

-- copy local indent
vim.opt.copyindent = true

-- columns to shift
vim.opt.shiftwidth = 0

local set_tabsize = function(tabsize, setter)
  for _, key in pairs { "tabstop" } do
    setter[key] = tabsize
  end
end

set_tabsize(2, vim.opt)

local detect_tabs = function(buf)
  local count = vim.api.nvim_buf_line_count(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, math.min(count, 99), true)

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
    vim.bo[buf].expandtab = false
  end

  local indent_lvs = {}
  for ts = 2, 4 do
    local divisibility = 0
    for _, line in pairs(lines) do
      local indent_lv = to.p_indent(line, ts)
      if indent_lv ~= 0 and indent_lv % ts == 0 then
        divisibility = divisibility + 1
      end
    end
    table.insert(indent_lvs, { ts, divisibility })
  end

  table.sort(indent_lvs, function(lhs, rhs)
    local lt, ld = unpack(lhs)
    local rt, rd = unpack(rhs)

    if ld == rd then
      return lt < rt
    else
      return ld > rd
    end
  end)

  local winner = unpack(indent_lvs)
  local tabsize = unpack(winner)
  return tabsize
end

vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  group = lib.group,
  callback = async(function(args)
    local buf = args.buf
    local tabsize = vim.b[buf].__tabsize__ or detect_tabs(buf)

    async.scheduled()
    if vim.api.nvim_buf_is_valid(buf) then
      set_tabsize(tabsize, vim.bo[buf])
    end
  end),
})

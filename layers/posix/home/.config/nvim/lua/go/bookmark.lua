local lib = require "go.lib"
local az = "abcdefghijklmnopqrstuvwxyz"

local hl = "IncSearch"

local mark_signs = function(args)
  local buf = args.buf
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end

  local count = vim.api.nvim_buf_line_count(buf)

  local marks = {}
  for key in string.gmatch(az, [[%w]]) do
    local big_key = string.upper(key)
    local b_row = unpack(vim.api.nvim_buf_get_mark(buf, key))
    local g_row, _, g_buf, _ = unpack(vim.api.nvim_get_mark(big_key, {}))

    if b_row ~= 0 then
      marks[key] = b_row
    end

    if g_row ~= 0 and g_buf == buf then
      marks[big_key] = g_row
    end
  end

  local ns = vim.api.nvim_create_namespace(az)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for name, row in pairs(marks) do
    local opts = {
      sign_text = name,
      hl_mode = "combine",
      sign_hl_group = hl,
      number_hl_group = hl,
    }

    if row >= 0 and row <= count then
      vim.api.nvim_buf_set_extmark(buf, ns, row - 1, 0, opts)
    end
  end
end

vim.api.nvim_create_autocmd(
  { "BufEnter", "CursorHold", "CursorHoldI" },
  { group = lib.group, callback = lib.throttle(99, mark_signs) }
)

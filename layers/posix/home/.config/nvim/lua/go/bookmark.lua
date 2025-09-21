local az = "abcdefghijklmnopqrstuvwxyz"

local hl = "IncSearch"

local mark_signs = function()
  local buf = vim.api.nvim_get_current_buf()

  local marks = {}
  for key in string.gmatch(az, [[%w]]) do
    local big_key = string.upper(key)
    local b_row, b_col = unpack(vim.api.nvim_buf_get_mark(buf, key))
    local g_row, g_col, g_buf = unpack(vim.api.nvim_get_mark(big_key, {}))

    if b_row ~= 0 and b_col ~= 0 then
      marks[key] = b_row
    end

    if g_row ~= 0 and g_col ~= 0 and g_buf == buf then
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
      number_hl_group = hl
    }
    vim.api.nvim_buf_set_extmark(buf, ns, row - 1, 0, opts)
  end
end

vim.api.nvim_create_autocmd(
  {"BufEnter", "CursorHold", "CursorHoldI"},
  {callback = mark_signs}
)

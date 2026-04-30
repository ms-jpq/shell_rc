local extending = { ["-"] = "_" }
for key, val in pairs(extending) do
  extending[val] = key
end

vim.keymap.set({ "n" }, [[~]], function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local text = unpack(vim.api.nvim_buf_get_text(0, row - 1, col, row - 1, col + 1, {}))
  local found = extending[text]

  if found == nil then
    return "~"
  end

  return "r" .. found .. [[<right>]]
end, { noremap = true, expr = true })

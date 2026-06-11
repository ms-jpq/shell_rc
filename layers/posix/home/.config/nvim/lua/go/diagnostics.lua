vim.diagnostic.config {
  severity_sort = true,
  virtual_lines = false,
  virtual_text = true,
}

local highest_severity = function(buf)
  local count = vim.diagnostic.count(buf)

  for level in ipairs(vim.diagnostic.severity) do
    if count[level] and count[level] > 0 then
      return level
    end
  end

  return nil
end

vim.keymap.set({ "n" }, "H", function()
  vim.diagnostic.open_float()
end)

vim.keymap.set({ "n" }, "[d", function()
  local severity = highest_severity(0)
  vim.diagnostic.jump { count = -vim.v.count1, severity = severity }
end)

vim.keymap.set({ "n" }, "]d", function()
  local severity = highest_severity(0)
  vim.diagnostic.jump { count = vim.v.count1, severity = severity }
end)

vim.keymap.set({ "n" }, [[<leader>d]], function()
  local severity = highest_severity(0)
  vim.diagnostic.setloclist { severity = severity }
end)

vim.keymap.set({ "n" }, [[<leader>D]], function()
  local severity = highest_severity()
  vim.diagnostic.setqflist { severity = severity }
end)

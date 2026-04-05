vim.diagnostic.config {
  severity_sort = true,
  virtual_lines = true,
  virtual_text = false
}

vim.keymap.set(
  "n",
  "H",
  function()
    vim.diagnostic.open_float()
  end
)

vim.keymap.set(
  "n",
  [[<leader>d]],
  function()
    vim.diagnostic.setloclist()
  end
)

vim.keymap.set(
  "n",
  [[<leader>D]],
  function()
    vim.diagnostic.setqflist()
  end
)

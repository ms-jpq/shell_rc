vim.opt.tagfunc = "v:lua.vim.lsp.tagfunc"
vim.opt.formatexpr = "v:lua.vim.lsp.formatexpr()"

vim.api.nvim_create_autocmd(
  {"BufEnter", "CursorHold", "InsertLeave"},
  {
    pattern = "<buffer>",
    command = [[silent! lua vim.lsp.codelens.refresh()]]
  }
)

vim.api.nvim_create_autocmd(
  {"CursorHold", "CursorHoldI"},
  {
    pattern = {"<buffer>"},
    command = [[silent! lua vim.lsp.buf.document_highlight()]]
  }
)

vim.api.nvim_create_autocmd(
  {"CursorMoved"},
  {
    pattern = {"<buffer>"},
    command = [[silent! lua vim.lsp.buf.clear_references()]]
  }
)

vim.keymap.set(
  "n",
  [[<leader>a]],
  function()
    vim.lsp.buf.code_action()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>d]],
  function()
    vim.diagnostic.setloclist()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>D]],
  function()
    vim.diagnostic.setqflist()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>s]],
  function()
    vim.lsp.buf.document_symbol()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>S]],
  function()
    vim.lsp.buf.workspace_symbol()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  "H",
  function()
    vim.diagnostic.open_float()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  "gp",
  function()
    vim.lsp.buf.definition()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  "gP",
  function()
    vim.lsp.buf.references()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>j]],
  function()
    vim.diagnostic.setloclist()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>J]],
  function()
    vim.lsp.buf.setqflist()
  end,
  {noremap = true}
)

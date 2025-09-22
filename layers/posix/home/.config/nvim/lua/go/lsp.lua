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

for _, mode in pairs {"n", "v"} do
  vim.keymap.set(
    mode,
    "H",
    function()
      vim.diagnostic.open_float()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    "gw",
    function()
      vim.lsp.buf.code_action()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    "gp",
    function()
      vim.lsp.buf.definition()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    "gP",
    function()
      vim.lsp.buf.references()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    [[<leader>j]],
    function()
      vim.diagnostic.setloclist()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    [[<leader>J]],
    function()
      vim.lsp.buf.setqflist()
    end,
    {noremap = true}
  )
end

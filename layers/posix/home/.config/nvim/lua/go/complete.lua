-- fuzzy search
vim.opt.completeopt:append { "fuzzy", "menuone", "noinsert", "noselect", "preview" }

-- dont follow unloaded buffers and tags
vim.opt.complete:remove { "u", "t" }
vim.opt.complete:append { "Fv:lua.vim.lsp.omnifunc" }

-- basic autocomplete
vim.opt.autocomplete = true

do
  local ce = vim.keycode [[<c-e>]]

  -- insert movement keys do not enter
  for _, key in pairs { "<esc>", "<c-c>", "<left>", "<right>", "<bs>", "<c-w>", "<c-u>" } do
    vim.keymap.set("i", key, function()
      return (vim.fn.pumvisible() == 1 and ce or "") .. key
    end, { expr = true, noremap = true })
  end

  vim.keymap.set(
    "i",
    "<cr>",
    [[pumvisible() ? (complete_info(['selected']).selected == -1 ? '<c-e><cr>' : '<c-y>') : '<cr>']],
    { noremap = true, expr = true }
  )

  vim.keymap.set(
    "i",
    "<tab>",
    [[pumvisible() && !empty(trim(strpart(getline('.'), 0, col('.') - 1))) ? '<c-n>' : '<tab>']],
    { noremap = true, expr = true }
  )

  vim.keymap.set(
    "i",
    "<s-tab>",
    [[pumvisible() && !empty(trim(strpart(getline('.'), 0, col('.') - 1))) ? '<c-p>' : '<bs>']],
    { noremap = true, expr = true }
  )
end

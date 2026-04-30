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
    end, { noremap = true, expr = true })
  end
end

do
  local function has_text_before_cursor()
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    return string.match(string.sub(line, 1, col), "%S") ~= nil
  end

  vim.keymap.set("i", [[<cr>]], function()
    if vim.fn.pumvisible() == 0 then
      return [[<cr>]]
    end
    if vim.fn.complete_info({ "selected" }).selected == -1 then
      return [[<c-e><cr>]]
    end
    return [[<c-y>]]
  end, { noremap = true, expr = true })

  vim.keymap.set("i", [[<tab>]], function()
    if vim.fn.pumvisible() ~= 0 and has_text_before_cursor() then
      return [[<c-n>]]
    end
    return [[<tab>]]
  end, { noremap = true, expr = true })

  vim.keymap.set("i", [[<s-tab>]], function()
    if vim.fn.pumvisible() ~= 0 and has_text_before_cursor() then
      return [[<c-p>]]
    end
    return [[<bs>]]
  end, { noremap = true, expr = true })
end

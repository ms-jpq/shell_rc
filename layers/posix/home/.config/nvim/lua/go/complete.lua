-- fuzzy search
vim.opt.completeopt:append { "fuzzy", "menuone", "noinsert", "noselect", "preview" }

-- dont follow unloaded buffers and tags
vim.opt.complete:remove { "u", "t" }
vim.opt.complete:append { "Fv:lua.vim.lsp.omnifunc" }

for key, dir in pairs { ["<c-j>"] = 1, ["<c-k>"] = -1 } do
  vim.keymap.set({ "i", "s" }, key, function()
    if vim.snippet.active { direction = dir } then
      vim.snippet.jump(dir)
    end
  end)
end

if vim.o.autocomplete then
  local ce = vim.keycode [[<c-e>]]

  local function has_text_before_cursor()
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local before_cursor = string.sub(line, 1, col)
    return string.match(before_cursor, "%S") ~= nil
  end

  -- insert movement keys do not enter
  for _, key in pairs { "<esc>", "<c-c>", "<bs>", "<c-w>", "<c-u>", "<c-r>" } do
    vim.keymap.set({ "i" }, key, function()
      return (vim.fn.pumvisible() == 1 and ce or "") .. key
    end, { noremap = true, expr = true })
  end

  vim.keymap.set({ "i", "s" }, [[<cr>]], function()
    if vim.fn.pumvisible() == 0 then
      return [[<cr>]]
    end
    if vim.fn.complete_info({ "selected" }).selected == -1 then
      return [[<c-e><cr>]]
    end
    return [[<c-y>]]
  end, { noremap = true, expr = true })

  vim.keymap.set({ "i", "s" }, [[<tab>]], function()
    if vim.fn.pumvisible() ~= 0 and has_text_before_cursor() then
      return [[<c-n>]]
    end
    return [[<tab>]]
  end, { noremap = true, expr = true })

  vim.keymap.set({ "i", "s" }, [[<s-tab>]], function()
    if vim.fn.pumvisible() ~= 0 and has_text_before_cursor() then
      return [[<c-p>]]
    end
    return [[<bs>]]
  end, { noremap = true, expr = true })
end
